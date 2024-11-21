# VPC Configuration
resource "aws_vpc" "default" {
  cidr_block           = var.vpc.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_prefix}-${var.env}-vpc"
  }
}

# Subnet Configuration
resource "aws_subnet" "public" {
  count             = length(var.vpc.public_subnets_cidr)
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.vpc.public_subnets_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_prefix}-${var.env}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.vpc.private_subnets_cidr)
  vpc_id            = aws_vpc.default.id
  cidr_block        = var.vpc.private_subnets_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_prefix}-${var.env}-private-subnet-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "${var.project_prefix}-${var.env}-igw"
  }
}

# Elastic IPs and NAT Gateways
resource "aws_eip" "nat" {
  count = length(var.vpc.public_subnets_cidr)
  vpc   = true
}

resource "aws_nat_gateway" "public_nat" {
  count        = length(var.vpc.public_subnets_cidr)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name = "${var.project_prefix}-${var.env}-nat-gateway-${count.index + 1}"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  count = length(var.vpc.public_subnets_cidr)
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_prefix}-${var.env}-public-route-${count.index + 1}"
  }
}

resource "aws_route_table" "private" {
  count = length(var.vpc.private_subnets_cidr)
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_nat[count.index].id
  }

  tags = {
    Name = "${var.project_prefix}-${var.env}-private-route-${count.index + 1}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count        = length(var.vpc.public_subnets_cidr)
  subnet_id    = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count        = length(var.vpc.private_subnets_cidr)
  subnet_id    = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Groups
resource "aws_security_group" "lb" {
  name        = "${var.project_prefix}-${var.env}-alb-sg"
  description = "Controls access to the ALB"
  vpc_id      = aws_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = var.app.port
    to_port     = var.app.port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_prefix}-${var.env}-alb-sg"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_prefix}-${var.env}-ecs-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id      = aws_vpc.default.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app.port
    to_port         = var.app.port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_prefix}-${var.env}-ecs-sg"
  }
}
