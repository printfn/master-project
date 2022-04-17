#--- EC2 

resource "aws_key_pair" "keypair" {
  key_name   = local.key_name
  public_key = file(local.public_key_path)
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "template_file" "user_data_file" {
  template = file("${path.module}/scripts/user_data.sh")
  vars = {
    region     = var.region
    account_id = local.account_id
  }
}

resource "aws_launch_configuration" "asg" {
  name_prefix   = format("%s-${terraform.workspace}", local.project_name)
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = local.instance_type
  key_name      = aws_key_pair.keypair.id

  security_groups = [aws_security_group.l42_sg.id]

  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.asg.name

  lifecycle {
    create_before_destroy = true
  }

  user_data = data.template_file.user_data_file.rendered
}

resource "aws_iam_instance_profile" "asg" {
  name = format("%s-asg-profile-${terraform.workspace}", local.project_name)
  role = aws_iam_role.asg.name
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name         = format("%s_asg", local.project_name)
    project_name = local.project_name
  }
}

resource "aws_iam_role" "asg" {
  name = format("%s-asg-role-${terraform.workspace}", local.project_name)
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "asg" {
  name = format("%s-asg-policy-${terraform.workspace}", local.project_name)
  role = aws_iam_role.asg.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "cloudwatch:*",
          "ec2:DescribeTags",
          "ec2:CreateTags",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeSecurity*",
          "ec2messages:*",
          "ecr:*",
          "logs:*",
          "route53:ChangeResourceRecordSets",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
          "ssm:*",
          "ssmmessages:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
          "s3:*"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:s3:::${local.user_data_bucket_name}",
          "arn:aws:s3:::${local.user_data_bucket_name}/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetEncryptionConfiguration"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}


#--- Auto-Scaling

resource "aws_autoscaling_group" "asg" {
  depends_on = [
    aws_launch_configuration.asg
  ]

  lifecycle {
    create_before_destroy = true
  }

  name_prefix               = format("%s-asg-${terraform.workspace}", local.project_name)
  vpc_zone_identifier       = aws_subnet.l42_subprv.*.id
  max_size                  = local.asg_count_max
  min_size                  = local.asg_count_min
  desired_capacity          = local.asg_count_desired
  wait_for_elb_capacity     = 1
  health_check_grace_period = 60
  force_delete              = false
  launch_configuration      = aws_launch_configuration.asg.id
  target_group_arns         = [aws_alb_target_group.albtargetgrp.arn]

  tag {
    key                 = "Name"
    value               = format("%s_linux", local.project_name)
    propagate_at_launch = true
  }

  tag {
    key                 = "project_name"
    value               = format("%s", local.project_name)
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = format("%s-asg-scale-up-${terraform.workspace}", local.project_name)
  scaling_adjustment     = 1 # add 1 ec2 instance to scale up
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name                = format("%s-asg-high-cpu-${terraform.workspace}", local.project_name)
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "EC2 CPU Utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = format("%s-asg-scale-down-${terraform.workspace}", local.project_name)
  scaling_adjustment     = -1 # remove 1 ec2 instance to scale down
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name                = format("%s-asg-low-cpu-${terraform.workspace}", local.project_name)
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "30"
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  alarm_description = "EC2 CPU Utilization"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}

resource "aws_autoscaling_schedule" "schedules" {
  for_each = local.asg_schedules

  scheduled_action_name  = each.key
  min_size               = coalesce(each.value.asg_count_min, local.asg_count_min)
  max_size               = coalesce(each.value.asg_count_max, local.asg_count_max)
  desired_capacity       = coalesce(each.value.asg_count_desired, local.asg_count_desired)
  recurrence             = each.value.schedule
  autoscaling_group_name = aws_autoscaling_group.asg.name
}


#--- Load Balancer

resource "aws_security_group" "alb" {
  name_prefix = format("%s-sg-${terraform.workspace}", local.project_name)
  vpc_id      = aws_vpc.l42_vpc.id
  # Allow all inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all inbound HTTPS requests
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  # "name_prefix": "l42-default-" is too long! 
  name_prefix        = format("%s", local.project_name)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.l42_subpub.*.id
  tags = {
    Name         = format("%s_alb", local.project_name)
    project_name = local.project_name
  }
}

resource "aws_lb_listener" "front_end_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.albtargetgrp.arn
  }
}

resource "aws_lb_listener" "front_end_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn   = var.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.albtargetgrp.arn
  }
}

resource "aws_alb_target_group" "albtargetgrp" {
  name                 = format("%s-lbtrggrp-${terraform.workspace}", local.project_name)
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.l42_vpc.id
  deregistration_delay = 30 # (Optional, equivalent to connection draining in classical ELB) Amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. The default value is 300 seconds.
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_attachment" "asgattachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_alb_target_group.albtargetgrp.arn
}

resource "aws_cloudwatch_log_group" "log_groups" {
  for_each = toset(local.ec2_log_groups)

  name              = "l42-${terraform.workspace}-${each.key}"
  retention_in_days = 365
}
