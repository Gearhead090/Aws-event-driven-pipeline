provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.project_name}-raw-data-${random_id.bucket_id.hex}"
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "reports_bucket" {
  bucket = "${var.project_name}-reports-${random_id.bucket_id.hex}"
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "data_processor_role" {
  name               = "${var.project_name}-data-processor-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "data_processor_policy" {
  role       = aws_iam_role.data_processor_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "${var.project_name}-s3-access-policy"
  role = aws_iam_role.data_processor_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = ["${aws_s3_bucket.data_bucket.arn}/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = ["${aws_s3_bucket.reports_bucket.arn}/*"]
      }
    ]
  })
}

data "archive_file" "data_processor_zip" {
  type        = "zip"
  source_file = "../lambda/data_processor.py"
  output_path = "data_processor.zip"
}

resource "aws_lambda_function" "data_processor" {
  filename         = data.archive_file.data_processor_zip.output_path
  function_name    = "${var.project_name}-data-processor"
  role             = aws_iam_role.data_processor_role.arn
  handler          = "data_processor.handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.data_processor_zip.output_base64sha256

  environment {
    variables = {
      REPORTS_BUCKET_NAME = aws_s3_bucket.reports_bucket.bucket
    }
  }
}

data "archive_file" "report_generator_zip" {
  type        = "zip"
  source_file = "../lambda/report_generator.py"
  output_path = "report_generator.zip"
}

resource "aws_lambda_function" "report_generator" {
  filename         = data.archive_file.report_generator_zip.output_path
  function_name    = "${var.project_name}-report-generator"
  role             = aws_iam_role.data_processor_role.arn
  handler          = "report_generator.handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.report_generator_zip.output_base64sha256

  environment {
    variables = {
      REPORTS_BUCKET_NAME = aws_s3_bucket.reports_bucket.bucket
    }
  }
}

resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = aws_s3_bucket.data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.data_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_bucket.arn
}

resource "aws_cloudwatch_event_rule" "daily_report_trigger" {
  name                = "${var.project_name}-daily-report-trigger"
  description         = "Triggers daily report generation"
  schedule_expression = "cron(0 0 * * ? *)" # Every day at midnight UTC
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_report_trigger.name
  target_id = "TriggerReportGeneratorLambda"
  arn       = aws_lambda_function.report_generator.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowCloudWatchInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.report_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_report_trigger.arn
}
