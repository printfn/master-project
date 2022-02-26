resource aws_s3_bucket "l42_bucket" {
  bucket_prefix = "l42-"
  force_destroy = true
}

resource "aws_s3_object" "l42_layer" {
  bucket = aws_s3_bucket.l42_bucket.bucket
  key = "L42PortableLinux.zip"
  source = "${path.module}/L42PortableLinux.zip"
  source_hash = filebase64sha256("L42PortableLinux.zip")
  force_destroy = true
}

resource "aws_lambda_layer_version" "l42_layer" {
  layer_name = "L42PortableLinux"

  s3_bucket = aws_s3_object.l42_layer.bucket
  s3_key = aws_s3_object.l42_layer.key

  source_code_hash = aws_s3_object.l42_layer.source_hash

  description = <<-EOS
    Contains the 42 compiler from https://l42.is.
    To reduce file size, 'libjfxwebkit.so' and 'jdk-16/lib/src.zip' have been removed.
  EOS

  compatible_runtimes = ["python3.9"]
  compatible_architectures = ["x86_64"]
}

data "archive_file" "l42_lambda" {
  type = "zip"
  source_dir = "${path.module}/lambda_package"
  output_path = "${path.module}/lambda_package.zip"
  output_file_mode = "0755"
}

resource "aws_s3_object" "l42_lambda" {
  bucket = aws_s3_bucket.l42_bucket.bucket
  key = "lambda_package.zip"
  source = "${path.module}/lambda_package.zip"
  source_hash = data.archive_file.l42_lambda.output_base64sha256
  force_destroy = true
}

resource "aws_cloudwatch_log_group" "l42_lambda" {
  name              = "/aws/lambda/${var.l42_lambda_name}"
  retention_in_days = 14
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
          "Resource": "arn:aws:logs:*:*:*",
          "Effect": "Allow"
        }
      ]
    }
  EOF
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
}

resource "aws_iam_role_policy_attachment" "l42_lambda_logs" {
  role       = aws_iam_role.l42_lambda.name
  policy_arn = aws_iam_policy.l42_lambda_logging.arn
}

resource "aws_lambda_function" "l42_lambda" {
  function_name = "${var.l42_lambda_name}"

  s3_bucket = aws_s3_object.l42_lambda.bucket
  s3_key    = aws_s3_object.l42_lambda.key

  runtime = "python3.9"
  handler = "lambda.lambda_handler"

  memory_size = 2048
  timeout = 30

  source_code_hash = data.archive_file.l42_lambda.output_base64sha256

  role = aws_iam_role.l42_lambda.arn
  layers = [aws_lambda_layer_version.l42_layer.arn]

  depends_on = [
    aws_iam_role_policy_attachment.l42_lambda_logs,
    aws_cloudwatch_log_group.l42_lambda,
  ]
}
