variable "region" {
  description = "AWS region"
  type        = string
}
variable "certificate_arn" {
  description = "Certificate ARN"
  type        = string
}

locals {
  // only alphanumeric and hyphens, max 6 chars
  project_name = "l42ec2"

  // networking
  vpc_cidr = "10.50.0.0/16"
  subpub_cidrs = [
    "10.50.101.0/24",
    "10.50.102.0/24"
  ]
  subprv_cidrs = [
    "10.50.201.0/24",
    "10.50.202.0/24"
  ]
  access_ip = "0.0.0.0/0"
  service_ports = [
    { # ssh
      from_port = 22,
      to_port   = 22
    },
    { # web http
      from_port = 80,
      to_port   = 80
    },
    { # web https
      from_port = 443,
      to_port   = 443
    }
  ]

  // compute
  key_name        = "l42_key"
  public_key_path = "./id_rsa.pub"
  instance_type   = "t2.micro"

  asg_count_min     = 1
  asg_count_max     = 3
  asg_count_desired = 2
  asg_schedules = {
    "Working hours" = {
      schedule          = "0 7 * * *"
      asg_count_min     = null
      asg_count_max     = null
      asg_count_desired = 2
    },
    "After working hours" = {
      schedule          = "0 18 * * *"
      asg_count_min     = null
      asg_count_max     = null
      asg_count_desired = 1
    }
  }

  account_id = data.aws_caller_identity.current.account_id

  user_data_bucket_name   = "${local.project_name}-userdata-${local.account_id}"
  user_data_bucket_region = var.region

  user_data_file_name_linux = "user_data.sh"
  user_data_s3_key_linux    = "user_data/${terraform.workspace}/${var.region}/${local.user_data_file_name_linux}"

  cwa_config_file_name_linux = "cwa_config_linux.json"
  cwa_config_s3_key_linux    = "cwa_config/${terraform.workspace}/${var.region}/${local.cwa_config_file_name_linux}"

  ec2_log_groups = [
    "linux"
  ]
}
