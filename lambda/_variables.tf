variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
}

locals {
  l42_lambda_name = "L42"
  tags = {
    Project_Name = "L42_Lambda"
    Author       = "tobias.heitland@gmail.com"
  }
}
