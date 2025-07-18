output "data_bucket_name" {
  description = "The name of the S3 bucket for raw data uploads."
  value       = aws_s3_bucket.data_bucket.bucket
}

output "reports_bucket_name" {
  description = "The name of the S3 bucket for storing generated reports."
  value       = aws_s3_bucket.reports_bucket.bucket
}

output "data_processor_lambda_name" {
  description = "The name of the data processing Lambda function."
  value       = aws_lambda_function.data_processor.function_name
}

output "report_generator_lambda_name" {
  description = "The name of the report generation Lambda function."
  value       = aws_lambda_function.report_generator.function_name
}