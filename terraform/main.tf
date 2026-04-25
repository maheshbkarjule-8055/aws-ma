provider "aws" {
  region = "ap-southeast-2"
}

# S3 bucket for project data
resource "aws_s3_bucket" "ma_bucket" {
  bucket = "aws-ma-data-pipeline-bucket"

  tags = {
    Project = "aws-ma"
    Owner   = "Mahesh"
  }
}

# Folder for input JSON
resource "aws_s3_object" "input_folder" {
  bucket = aws_s3_bucket.ma_bucket.bucket
  key    = "input/"
  source = "/dev/null"
}

# Folder for output processed files
resource "aws_s3_object" "output_folder" {
  bucket = aws_s3_bucket.ma_bucket.bucket
  key    = "output/"
  source = "/dev/null"
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