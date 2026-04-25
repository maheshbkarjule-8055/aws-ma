# AWS Data Pipeline Architecture

JSON data lands in S3.

Glue PySpark job reads nested JSON.

Data is split into:
1. ma.customer_info
2. ma.orders

Step Function orchestrates:
S3 → Glue → Redshift COPY → Validation