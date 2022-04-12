#--- ECS CLuster
resource "aws_ecs_cluster" "app" {
  name = "${local.project_name}-${local.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = local.tags
}

#--- ECS (Replica) Service with load balancer
resource "aws_ecs_service" "app" {
  name                              = "${local.project_name}-${local.environment}"
  cluster                           = aws_ecs_cluster.app.id
  launch_type                       = "FARGATE"
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = local.replicas
  health_check_grace_period_seconds = local.health_check_grace_period_seconds

  network_configuration {
    security_groups  = [aws_security_group.sg_task.id]
    subnets          = aws_subnet.subprv.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.trg.id
    container_name   = local.container_name
    container_port   = local.container_port
  }

  tags                    = local.tags
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  # [after initial apply] don't override changes made to task_definition
  # from outside of terraform (i.e. fargate cli)
  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_appautoscaling_target" "app_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.ecs_autoscale_max_instances
  min_capacity       = var.ecs_autoscale_min_instances
}

#--- ECS Task
resource "aws_ecs_task_definition" "app" {
  family                   = "${local.project_name}-${local.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024 # 1 CPU = 1024 cpu units
  memory                   = 2048 # MB

  # ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume (e.g. pulling images, writing to CloudWatch logs)
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  # ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services.
  task_role_arn = aws_iam_role.ecs_task_role.arn

  container_definitions = <<DEFINITION
[
  {
    "name": "${local.container_name}",
    "image": "${var.container_image}",
    "essential": true,
    "portMappings": [
      {
        "protocol": "tcp",
        "containerPort": ${local.container_port},
        "hostPort": ${local.container_port}
      }
    ],
    "runtimePlatform": {
      "operatingSystemFamily": "LINUX",
      "cpuArchitecture": null
    },
    "environment": [
      {
        "name": "PORT",
        "value": "${local.container_port}"
      },
      {
        "name": "HEALTHCHECK",
        "value": "${local.health_check_path}"
      },
      {
        "name": "ENABLE_LOGGING",
        "value": "true"
      },
      {
        "name": "PRODUCT",
        "value": "${local.project_name}"
      },
      {
        "name": "ENVIRONMENT",
        "value": "${local.environment}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/fargate/service/${local.project_name}-${local.environment}",
        "awslogs-region": "${local.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION

  tags = local.tags
}

#--- ECS Task Execution Role
# Defines the permission for setting up the task (= container),
# NOT for executing the task (this would be the task role, see below)!
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
# The task execution role grants the Amazon ECS container and Fargate agents permission to make AWS API calls on your behalf. The task execution IAM role is required depending on the requirements of your task. You can have multiple task execution roles for different purposes and services associated with your account.
# The following are common use cases for a task execution IAM role:
# - Your task is hosted on AWS Fargate or on an external instance and is pulling a container image from an Amazon ECR private repository.
# - Your task sends container logs to CloudWatch Logs using the awslogs log driver.
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${local.project_name}-${local.environment}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = local.tags
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  # This pre-defined AWS policy has the following content:
  # {
  #     "Version": "2012-10-17",
  #     "Statement": [
  #         {
  #             "Effect": "Allow",
  #             "Action": [
  #                 "ecr:GetAuthorizationToken",
  #                 "ecr:BatchCheckLayerAvailability",
  #                 "ecr:GetDownloadUrlForLayer",
  #                 "ecr:BatchGetImage",
  #                 "logs:CreateLogStream",
  #                 "logs:PutLogEvents"
  #             ],
  #             "Resource": "*"
  #         }
  #     ]
  # }
}


#--- ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.project_name}-${local.environment}-ecs-task-role"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": ["ecs-tasks.amazonaws.com"]
    },
    "Action": "sts:AssumeRole"
  }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${local.project_name}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ecs:*",
        "ecr:*",
        "cloudwatch:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}


#--- Task SG

resource "aws_security_group" "sg_task" {
  name        = "${local.project_name}-${local.environment}-task"
  description = "ingress and egress only from alb on container port"
  vpc_id      = aws_vpc.vpc.id

  tags = local.tags
}

resource "aws_security_group_rule" "sg_task_ingress_rule" {
  description              = "Only allow ingress connections from load balancer on container port"
  type                     = "ingress"
  from_port                = local.container_port
  to_port                  = local.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_alb.id

  security_group_id = aws_security_group.sg_task.id
}

resource "aws_security_group_rule" "sg_task_egress_rule" {
  description = "Allows task to establish connections to all resources on all ports"
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.sg_task.id
}


#--- CloudWatch Log Group
resource "aws_cloudwatch_log_group" "logs" {
  name              = local.log_group_name
  retention_in_days = local.logs_retention_in_days
  tags              = local.tags
}
