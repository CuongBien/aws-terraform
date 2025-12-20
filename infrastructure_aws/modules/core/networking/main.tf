# ========================================
# CORE - NETWORKING MODULE
# ========================================
# VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
# VPC Flow Logs, VPC Endpoints for SSM
# ========================================

# Data source for current region
data "aws_region" "current" {}

# ========================================
# VPC
# ========================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# ========================================
# PUBLIC SUBNETS
# ========================================

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-${var.availability_zones[count.index % length(var.availability_zones)]}"
      Tier = "public"
    }
  )
}

# ========================================
# PRIVATE SUBNETS - WEB TIER
# ========================================

resource "aws_subnet" "private_web" {
  count = length(var.private_web_subnet_cidrs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_web_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-web-${var.availability_zones[count.index % length(var.availability_zones)]}"
      Tier = "private-web"
    }
  )
}

# ========================================
# PRIVATE SUBNETS - APP TIER
# ========================================

resource "aws_subnet" "private_app" {
  count = length(var.private_app_subnet_cidrs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-app-${var.availability_zones[count.index % length(var.availability_zones)]}"
      Tier = "private-app"
    }
  )
}

# ========================================
# PRIVATE SUBNETS - DATABASE TIER
# ========================================

resource "aws_subnet" "private_db" {
  count = length(var.private_db_subnet_cidrs)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-db-${var.availability_zones[count.index % length(var.availability_zones)]}"
      Tier = "private-db"
    }
  )
}

# ========================================
# INTERNET GATEWAY
# ========================================

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# ========================================
# ELASTIC IP FOR NAT GATEWAY
# ========================================

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-eip"
    }
  )
}

# ========================================
# NAT GATEWAY
# ========================================

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-gw"
    }
  )

  depends_on = [aws_internet_gateway.igw]
}

# ========================================
# ROUTE TABLES
# ========================================

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

# Private Route Table (for Web & App tiers - with NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-rt"
    }
  )
}

# Database Private Route Table (no internet access)
resource "aws_route_table" "db_private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-private-rt"
    }
  )
}

# ========================================
# ROUTE TABLE ASSOCIATIONS
# ========================================

# Associate Public Subnets
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate Private Web Subnets
resource "aws_route_table_association" "private_web" {
  count = length(var.private_web_subnet_cidrs)
  
  subnet_id      = aws_subnet.private_web[count.index].id
  route_table_id = aws_route_table.private.id
}

# Associate Private App Subnets
resource "aws_route_table_association" "private_app" {
  count = length(var.private_app_subnet_cidrs)
  
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

# Associate Private DB Subnets
resource "aws_route_table_association" "private_db" {
  count = length(var.private_db_subnet_cidrs)
  
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.db_private.id
}

# ========================================
# VPC FLOW LOGS
# ========================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc-flow-logs"
    }
  )
}

resource "aws_flow_log" "main" {
  iam_role_arn         = var.flow_log_iam_role_arn
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-flow-log"
    }
  )
}

# ========================================
# VPC ENDPOINTS FOR SSM
# ========================================

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.project_name}-vpc-endpoint-sg"
  description = "Allow HTTPS traffic to VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc-endpoint-sg"
    }
  )
}

# SSM Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_web[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ssm-endpoint"
    }
  )
}

# SSM Messages Endpoint
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_web[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ssmmessages-endpoint"
    }
  )
}

# EC2 Messages Endpoint
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private_web[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ec2messages-endpoint"
    }
  )
}
