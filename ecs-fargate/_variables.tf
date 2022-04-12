variable "region" {
  type        = string
  description = "AWS region as a deployment target"
}

# The minimum number of containers that should be running.
# Must be at least 1.
# used by both autoscale-perf.tf and autoscale.time.tf
# For production, consider using at least "2".
variable "ecs_autoscale_min_instances" {
  type        = string
  default     = "1"
  description = <<EOT
  The minimum number of containers that should be running.
  Must be at least 1.
  used by both autoscale-perf.tf and autoscale.time.tf
  For production, consider using at least "2".
  EOT
}

# The maximum number of containers that should be running.
# used by both autoscale-perf.tf and autoscale.time.tf
variable "ecs_autoscale_max_instances" {
  type        = string
  default     = "2"
  description = "The maximum number of containers that should be running. Used by both autoscale-perf.tf and autoscale.time.tf"
}

# The docker contaienr image to deploy with the infrastructure.
# Defaults to Amazon's simple web server example which runs on port 80, returns a web page, helth path = "/"
# Set this variable to your app docker image!
variable "container_image" {
  type        = string
  default     = "amazon/amazon-ecs-sample" # runs on port 80, returns a web page, health path = "/"
  description = "The default docker image to deploy with the infrastructure."
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the certificate we are using for https://r53.heitland-ite.de"
}

locals {
  project_name = "l42"
  environment  = "dev"
  account_id   = data.aws_caller_identity.current.account_id
  region       = data.aws_region.current.name

  vpc_cidr = "10.0.0.0/16"

  # ALB needs at least two public subnets!
  subpub_cidrs = [
    "10.0.0.0/24",
    "10.0.2.0/24",
  ]

  # we can go with one or more private subnets for the ECS tasks
  subprv_cidrs = [
    "10.0.1.0/24",
    #    "10.0.3.0/24",
  ]

  logs_retention_in_days = 90
  log_group_name         = "/fargate/service/${local.project_name}-${local.environment}"

  replicas       = "1" # how many copies of the app container do we want to run?
  container_name = "l42"
  container_port = "80"

  internal_lb                       = false
  lb_access_logs_expiration_days    = 30
  deregistration_delay              = "30"      # The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused
  health_check_path                 = "/health" # The path to the health check for the load balancer to know if the container(s) are ready
  health_check_interval             = "60"      # How often to check the liveliness of the container
  health_check_timeout              = "10"      # How long to wait for the response on the health check path
  health_check_matcher              = "200"     # What HTTP response code to listen for
  health_check_grace_period_seconds = "10"      # Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers.
  tags = {
    Name        = local.project_name
    Environment = local.environment
  }
}