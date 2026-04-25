import sys
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)

# Read JSON from S3
df = spark.read.option("multiline", "true").json(
    "s3://an-aws-ma-data-pipeline-bucket/input-data/customer_orders.json"
#    "s3://mahesh-aws-ma-data-pipeline-2026/input/customer_orders.json"
)

# Flatten customer data
customer_df = df.select(
    "customer_id",
    "customer_name",
    "email",
    "phone",
    "city",
    "registration_date"
)

# Flatten orders data
orders_df = df.selectExpr(
    "customer_id",
    "explode(orders) as order"
).selectExpr(
    "customer_id",
    "order.order_id",
    "order.order_date",
    "order.product_name",
    "order.quantity",
    "order.price"
)

# Write parquet output for now
customer_df.write.mode("overwrite").parquet(
    "s3://an-aws-ma-data-pipeline-bucket/output-data/customer"
)

orders_df.write.mode("overwrite").parquet(
    "s3://an-aws-ma-data-pipeline-bucket/output-data/order"
)

job.commit()

