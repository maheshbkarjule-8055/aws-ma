# AWS Data Engineering Pipeline

JSON file lands in S3
        ↓
Glue PySpark ETL
        ↓
Flatten nested orders array
        ↓
Split into customer_info and orders tables
        ↓
Load to Redshift using COPY
        ↓
Orchestrate with Step Functions
        ↓
Infra managed with Terraform