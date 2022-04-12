#--- ECR Endpoint SG
resource "aws_security_group" "vpce" {
  name        = "${local.project_name}-${local.environment}-vpce"
  description = "ingress and egress for VPC endpoints"
  vpc_id      = aws_vpc.vpc.id

  tags = local.tags
}

resource "aws_security_group_rule" "vpce_ingress_rule" {
  description = "Allow all ingress traffic"
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = [local.vpc_cidr]

  security_group_id = aws_security_group.vpce.id
}

resource "aws_security_group_rule" "vpce_egress_rule" {
  description = "Allow all egress traffic"
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.vpce.id
}

#--- VPC Endpoint for ECR API
data "aws_vpc_endpoint_service" "ecr_api" {
  service = "ecr.api"
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = data.aws_vpc_endpoint_service.ecr_api.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = aws_subnet.subprv.*.id
  private_dns_enabled = true
  tags                = local.tags
}

#--- VPC Endpoint for ECR DKR
data "aws_vpc_endpoint_service" "ecr_dkr" {
  service = "ecr.dkr"
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = data.aws_vpc_endpoint_service.ecr_dkr.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = aws_subnet.subprv.*.id
  private_dns_enabled = true
  tags                = local.tags
}

#--- CloudWatch Endpoints
data "aws_vpc_endpoint_service" "sns" {
  service = "sns"
}

resource "aws_vpc_endpoint" "sns" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = data.aws_vpc_endpoint_service.sns.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = aws_subnet.subprv.*.id
  private_dns_enabled = true
  tags                = local.tags
}


data "aws_vpc_endpoint_service" "monitoring" {
  service = "monitoring"
}

resource "aws_vpc_endpoint" "monitoring" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = data.aws_vpc_endpoint_service.monitoring.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = aws_subnet.subprv.*.id
  private_dns_enabled = true
  tags                = local.tags
}

data "aws_vpc_endpoint_service" "logs" {
  service = "logs"
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = data.aws_vpc_endpoint_service.logs.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = aws_subnet.subprv.*.id
  private_dns_enabled = true
  tags                = local.tags
}

data "aws_vpc_endpoint_service" "events" {
  service = "events"
}

resource "aws_vpc_endpoint" "events" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = data.aws_vpc_endpoint_service.events.service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.vpce.id]
  subnet_ids          = aws_subnet.subprv.*.id
  private_dns_enabled = true
  tags                = local.tags
}
