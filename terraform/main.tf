provider "aws" {
  region = "ap-southeast-2"
}

# S3 bucket for project data
resource "aws_s3_bucket" "ma_bucket" {
  bucket = "an-aws-ma-data-pipeline-bucket"

  tags = {
    Project = "aws-ma"
    Owner   = "Mahesh"
  }
}

# Folder for input JSON
resource "aws_s3_object" "input_folder" {
  bucket = aws_s3_bucket.ma_bucket.bucket
  key    = "input/empty.txt"
  source = "empty.txt"
}

# Folder for output processed files
resource "aws_s3_object" "output_folder" {
  bucket = aws_s3_bucket.ma_bucket.bucket
  key    = "output/empty.txt"
  source = "empty.txt"
}

resource "aws_iam_role" "step_function_role" {
  name = "aws-ma-step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Effect = "Allow"
      Sid = ""
    }]
  })
}

resource "aws_iam_role_policy" "step_function_execution_policy" {
  name = "aws-ma-step-function-execution-policy"
  role = aws_iam_role.step_function_role.id
   policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


resource "aws_sfn_state_machine" "ma_pipeline" {
  name     = "aws-ma-pipeline"
  role_arn = aws_iam_role.step_function_role.arn

  definition = file("../step_function/ma_pipeline.json")
}


#run this every  dat at 9:00 AM utc for indian time 2:30 PM ist
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "aws-ma-daily-trigger"
  description         = "Daily trigger for Step Function"
  schedule_expression = "cron(0 9 * * ? *)"
}

resource "aws_cloudwatch_event_target" "step_function_target" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "StepFunctionTarget"
  arn       = aws_sfn_state_machine.ma_pipeline.arn
  role_arn  = aws_iam_role.step_function_role.arn
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "aws-ma-eventbridge-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "states:StartExecution"
      ]
      Effect   = "Allow"
      Resource = aws_sfn_state_machine.ma_pipeline.arn
    }]
  })
}

resource "aws_iam_role_policy" "step_function_glue_policy" {
  name = "aws-ma-stepfunction-glue-policy"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:BatchStopJobRun"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.ma_bucket.bucket
  key    = "scripts/customer_orders_etl.py"
  source = "../glue_jobs/customer_orders_etl.py"
}

resource "aws_iam_role" "glue_role" {
  name = "aws-ma-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "glue.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3_policy" {
  name = "aws-ma-glue-s3-policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_glue_job" "customer_orders_job" {
  name     = "ma-customer-orders-job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.ma_bucket.bucket}/scripts/customer_orders_etl.py"
    python_version  = "3"
  }

  glue_version      = "4.0"
  max_retries       = 1
  timeout           = 10
  number_of_workers = 2
  worker_type       = "G.1X"

  default_arguments = {
    "--job-language" = "python"
  }
}


