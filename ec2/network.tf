#-- networking/main.tf ---
data "aws_availability_zones" "available" {}

resource "aws_vpc" "l42_vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name         = format("%s_vpc", local.project_name)
    project_name = local.project_name
  }
}

resource "aws_internet_gateway" "l42_igw" {
  vpc_id = aws_vpc.l42_vpc.id

  tags = {
    Name         = format("%s_igw", local.project_name)
    project_name = local.project_name
  }
}

resource "aws_subnet" "l42_subpub" {
  count = length(local.subpub_cidrs)

  vpc_id                  = aws_vpc.l42_vpc.id
  cidr_block              = local.subpub_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name         = format("%s_subpub_%d", local.project_name, count.index + 1)
    project_name = local.project_name
  }
}

resource "aws_subnet" "l42_subprv" {
  count = length(local.subprv_cidrs)

  vpc_id                  = aws_vpc.l42_vpc.id
  cidr_block              = local.subprv_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name         = format("%s_subprv_%d", local.project_name, count.index + 1)
    project_name = local.project_name
  }
}

resource "aws_security_group" "l42_sg" {
  name        = "l42_sgpub"
  description = "Used for access to the public instances"
  vpc_id      = aws_vpc.l42_vpc.id
  dynamic "ingress" {
    for_each = [for s in local.service_ports : {
      from_port = s.from_port
      to_port   = s.to_port
    }]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value.to_port == 27017 ? "0.1.2.3/32" : local.access_ip]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name         = format("%s_sgpub", local.project_name)
    project_name = local.project_name
  }
}
# Public route table, allows all outgoing traffic to go the the internet gateway.
# https://www.terraform.io/docs/providers/aws/r/route_table.html?source=post_page-----1a7fb9a336e9----------------------
resource "aws_route_table" "l42_rtpub" {
  vpc_id = aws_vpc.l42_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.l42_igw.id
  }
  tags = {
    Name         = format("%s_l42_rtpub", local.project_name)
    project_name = local.project_name
  }
}
# connect every public subnet with our public route table
resource "aws_route_table_association" "l42_rtpubassoc" {
  count = length(local.subpub_cidrs)

  subnet_id      = aws_subnet.l42_subpub.*.id[count.index]
  route_table_id = aws_route_table.l42_rtpub.id
}

# If the subnet is not associated with any route by default it will be 
# associated automatically with this Private Route table.
# That's why we don't need an aws_route_table_association for private route tables.
# When Terraform first adopts the Default Route Table, it immediately removes all defined routes. 
# It then proceeds to create any routes specified in the configuration. 
# This step is required so that only the routes specified in the configuration present in the 
# Default Route Table.
# https://www.terraform.io/docs/providers/aws/r/default_route_table.html
resource "aws_default_route_table" "l42_rtprv" {
  default_route_table_id = aws_vpc.l42_vpc.default_route_table_id
  tags = {
    Name         = format("%s_l42_rtprv", local.project_name)
    project_name = local.project_name
  }
}
