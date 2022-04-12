resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = local.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = local.tags
}

resource "aws_subnet" "subpub" {
  count = length(local.subpub_cidrs)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.subpub_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.tags,
    { Name = format("%s_subpub_%d", local.project_name, count.index + 1) }
  )
}

resource "aws_subnet" "subprv" {
  count = length(local.subprv_cidrs)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = local.subprv_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.tags,
    { Name = format("%s_subprv_%d", local.project_name, count.index + 1) }
  )
}

# Public route table, allows all outgoing traffic to go the the internet gateway.
# https://www.terraform.io/docs/providers/aws/r/route_table.html?source=post_page-----1a7fb9a336e9----------------------
resource "aws_route_table" "rtpub" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = local.tags
}

# connect every public subnet with our public route table
resource "aws_route_table_association" "rtpubassoc" {
  count = length(local.subpub_cidrs)

  subnet_id      = aws_subnet.subpub.*.id[count.index]
  route_table_id = aws_route_table.rtpub.id
}

# If the subnet is not associated with any route by default it will be
# associated automatically with this Private Route table.
# That's why we don't need an aws_route_table_association for private route tables.
# When Terraform first adopts the Default Route Table, it immediately removes all defined routes.
# It then proceeds to create any routes specified in the configuration.
# This step is required so that only the routes specified in the configuration present in the
# Default Route Table.
# https://www.terraform.io/docs/providers/aws/r/default_route_table.html
resource "aws_default_route_table" "rtprv" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  tags                   = local.tags
}

resource "aws_eip" "nat" {
  count = length(local.subprv_cidrs)

  vpc  = true
  tags = local.tags

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "main" {
  count = length(local.subprv_cidrs)

  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.subpub.*.id, count.index)
  tags          = local.tags
}

# Create a new route table for the private subnets
# And make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count = length(local.subprv_cidrs)

  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.main.*.id, count.index)
  }
  tags = local.tags
}

# Explicitely associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
  count = length(local.subprv_cidrs)

  subnet_id      = element(aws_subnet.subprv.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}
