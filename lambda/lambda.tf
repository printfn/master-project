resource "aws_s3_object" "l42_lambda" {
  bucket        = aws_s3_bucket.l42_bucket.bucket
  key           = "l42_package.zip"
  source        = "${path.module}/../artifacts/l42_package.zip"
  source_hash   = filesha256("${path.module}/../artifacts/l42_package.zip")
  force_destroy = true
  tags          = local.tags
}

resource "aws_cloudwatch_log_group" "l42_lambda" {
  name              = "/aws/lambda/${local.l42_lambda_name}"
  retention_in_days = 14
  tags              = local.tags
}

resource "aws_iam_policy" "l42_lambda_logging" {
  name        = "l42_lambda_logging"
  path        = "/"
  description = "IAM policy for logging from the 42 Lambda"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "${aws_cloudwatch_log_group.l42_lambda.arn}:*",
          "Effect": "Allow"
        }
      ]
    }
  EOF
  tags   = local.tags
}

resource "aws_iam_role" "l42_lambda" {
  name = "l42_lambda_role"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  EOF
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "l42_lambda_logs" {
  role       = aws_iam_role.l42_lambda.name
  policy_arn = aws_iam_policy.l42_lambda_logging.arn
}

resource "aws_lambda_function" "l42_lambda" {
  function_name = local.l42_lambda_name

  s3_bucket = aws_s3_object.l42_lambda.bucket
  s3_key    = aws_s3_object.l42_lambda.key

  runtime = "provided.al2"
  handler = "_"

  memory_size                    = 1536
  timeout                        = 30
  reserved_concurrent_executions = 20

  source_code_hash = filebase64sha256(aws_s3_object.l42_lambda.source)

  role = aws_iam_role.l42_lambda.arn

  depends_on = [
    aws_iam_role_policy_attachment.l42_lambda_logs,
    aws_cloudwatch_log_group.l42_lambda,
  ]
  tags = local.tags
}

resource "aws_lambda_function_url" "l42_lambda_url" {
  function_name      = aws_lambda_function.l42_lambda.function_name
  authorization_type = "NONE"
}
