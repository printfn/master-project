resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.alb.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn # to go with http, remove this line and change HTTPS to HTTP and 443 to 80

  default_action {
    target_group_arn = aws_alb_target_group.trg.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302" # 302 = temporary redirect to https; with 301 = permanent redirect we can get into trouble with browser caching
    }
  }
}

#--- Load balancer SG
resource "aws_security_group" "sg_alb" {
  name        = "${local.project_name}-${local.environment}-alb"
  description = "ingress from everyone on port 80 and 443, egress only to container on container port 80"
  vpc_id      = aws_vpc.vpc.id

  tags = local.tags
}

resource "aws_security_group_rule" "ingress_alb_https" {
  type        = "ingress"
  description = "HTTPS open for everyone"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.sg_alb.id
}

resource "aws_security_group_rule" "ingress_alb_http" {
  type        = "ingress"
  description = "HTTP open for everyone"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.sg_alb.id
}

resource "aws_security_group_rule" "sg_alb_egress_rule_task" {
  description              = "Only allow egress on container_port 80 to container"
  type                     = "egress"
  from_port                = local.container_port
  to_port                  = local.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_task.id

  security_group_id = aws_security_group.sg_alb.id
}

resource "aws_alb" "alb" {
  name = "${local.project_name}-${local.environment}-alb"

  # launch lbs in public or private subnets based on "internal_lb" variable
  internal        = local.internal_lb
  subnets         = local.internal_lb == true ? aws_subnet.subprv.*.id : aws_subnet.subpub.*.id
  security_groups = [aws_security_group.sg_alb.id]
  tags            = local.tags

  # enable access logs in order to get support from aws
  /*access_logs {
    enabled = true
    bucket  = aws_s3_bucket.alb_access_logs.bucket
  }*/
}

resource "aws_alb_target_group" "trg" {
  name                 = "${local.project_name}-${local.environment}-trg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.vpc.id
  target_type          = "ip"
  deregistration_delay = local.deregistration_delay

  health_check {
    path                = local.health_check_path
    matcher             = local.health_check_matcher
    interval            = local.health_check_interval
    timeout             = local.health_check_timeout
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.tags
}

data "aws_elb_service_account" "alb" {
}

# bucket for storing ALB access logs
/*resource "aws_s3_bucket" "alb_access_logs" {
  bucket        = "${local.project_name}-${local.environment}-alb-access-logs-${data.aws_caller_identity.current.account_id}"
  acl           = "private"
  tags          = local.tags
  force_destroy = true

  lifecycle_rule {
    id                                     = "cleanup"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 1
    prefix                                 = ""

    expiration {
      days = local.lb_access_logs_expiration_days
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb" {
  # provider = aws.eu-west-2

  bucket = aws_s3_bucket.alb_access_logs.id

  # Whether Amazon S3 should block public bucket policies for this bucket. Defaults to false.
  # Enabling this setting does not affect the existing bucket policy. When set to true causes Amazon S3 to:
  # Reject calls to PUT Bucket policy if the specified bucket policy allows public access.
  block_public_acls = true

  # Whether Amazon S3 should block public bucket policies for this bucket. Defaults to false.
  # Enabling this setting does not affect the existing bucket policy. When set to true causes Amazon S3 to:
  # Reject calls to PUT Bucket policy if the specified bucket policy allows public access.
  block_public_policy = true

  # Whether Amazon S3 should ignore public ACLs for this bucket. Defaults to false.
  # Enabling this setting does not affect the persistence of any existing ACLs and doesn't prevent new public ACLs from being set. When set to true causes Amazon S3 to:
  # Ignore public ACLs on this bucket and any objects that it contains.
  ignore_public_acls = true

  # Whether Amazon S3 should restrict public bucket policies for this bucket. Defaults to false.
  # Enabling this setting does not affect the previously stored bucket policy, except that public and cross-account access within the public bucket policy,
  # including non-public delegation to specific accounts, is blocked. When set to true:
  # Only the bucket owner and AWS Services can access this buckets if it has a public policy.
  restrict_public_buckets = true
}

# give load balancing service access to the bucket
resource "aws_s3_bucket_policy" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.alb_access_logs.arn}",
        "${aws_s3_bucket.alb_access_logs.arn}/*"
      ],
      "Principal": {
        "AWS": [ "${data.aws_elb_service_account.alb.arn}" ]
      }
    }
  ]
}
POLICY
}
*/
