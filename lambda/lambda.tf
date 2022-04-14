resource "aws_s3_object" "l42_layer" {
  bucket        = aws_s3_bucket.l42_bucket.bucket
  key           = "lambda_layer.zip"
  source        = "${path.module}/lambda_layer.zip"
  source_hash   = filebase64sha256("lambda_layer.zip")
  force_destroy = true
  tags          = local.tags
}

resource "aws_lambda_layer_version" "l42_layer" {
  layer_name = "l42_lambda_layer"

  s3_bucket = aws_s3_object.l42_layer.bucket
  s3_key    = aws_s3_object.l42_layer.key

  source_code_hash = aws_s3_object.l42_layer.source_hash

  description = <<-EOS
    Based on the 42 compiler from https://l42.is.
  EOS

  compatible_runtimes      = ["provided.al2"]
  compatible_architectures = ["x86_64"]
}

data "archive_file" "l42_lambda" {
  type             = "zip"
  source_dir       = "${path.module}/lambda_package"
  output_path      = "${path.module}/lambda_package.zip"
  output_file_mode = "0755"
}

resource "aws_s3_object" "l42_lambda" {
  bucket        = aws_s3_bucket.l42_bucket.bucket
  key           = "lambda_package.zip"
  source        = "${path.module}/lambda_package.zip"
  source_hash   = data.archive_file.l42_lambda.output_base64sha256
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

  memory_size = 2048
  timeout     = 30

  source_code_hash = data.archive_file.l42_lambda.output_base64sha256

  role   = aws_iam_role.l42_lambda.arn
  layers = [aws_lambda_layer_version.l42_layer.arn]

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
