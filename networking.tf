# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.creator_tag}-${var.environment}-vpc"
  }
}

# Subnets
# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.creator_tag}-${var.environment}-igw"
    Environment = var.environment
  }
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.vpc_public_subnets)
  cidr_block              = element(var.vpc_public_subnets, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.creator_tag}-${var.environment}-${element(data.aws_availability_zones.available.names, count.index)}-public-subnet"
  }
}


# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.vpc_private_subnets)
  cidr_block              = element(var.vpc_private_subnets, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.creator_tag}-${var.environment}-${element(data.aws_availability_zones.available.names, count.index)}-private-subnet"
  }
}


# Routing tables to route traffic for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.creator_tag}-${var.environment}-private-route-table"
  }
}

# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.creator_tag}-${var.environment}-public-route-table"
  }
}

# Route for Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# Route table associations for both Public & Private Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.vpc_public_subnets)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.vpc_private_subnets)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}


resource "aws_security_group" "default" {
  name        = "${var.creator_tag}-default-sg"
  description = "Default SG to alllow traffic from the VPC"
  vpc_id      = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc
  ]

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "sg-default" {
  name        = "${var.creator_tag}-AllowRemoteToEC2"
  description = "Allow access to RDP/SSH to EC2"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.ec2_security_group_config
    content {
      description      = ingress.value["description"]
      from_port        = ingress.value["port"]
      to_port          = ingress.value["port"]
      protocol         = ingress.value["protocol"]
      cidr_blocks      = ingress.value["cidr_blocks"]
      ipv6_cidr_blocks = ingress.value["ipv6_cidr_blocks"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "${var.creator_tag}-AllowRemoteToEC2"
    creator = var.creator_tag
  }
}

resource "aws_security_group" "sg-ec2-fsx" {
  name        = "${var.creator_tag}-AllowAllTrafficEC2ToFSxN"
  description = "Allow all outbound access to FSxN"
  vpc_id      = aws_vpc.vpc.id

  egress {
    description = "All Ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.creator_tag}-AllowAllTrafficEC2ToFSxN"
  }
}

resource "aws_security_group" "sg-fsx" {
  name        = "${var.creator_tag}-AllowTrafficToFSX"
  description = "Allow all inbound and outbound access to FSXN"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "All Ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All Ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.creator_tag}-AllowEC2ToFSX"
  }
}

resource "aws_security_group_rule" "VPCToFSXRule" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg-fsx.id
  security_group_id        = aws_vpc.vpc.default_security_group_id
}
