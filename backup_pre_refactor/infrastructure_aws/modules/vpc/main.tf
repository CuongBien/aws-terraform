# VPC Module Configuration

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name = "${var.project_name}-public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = {
    Name = "${var.project_name}-private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# NAT Gateway in Public Subnet [0]
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw] # Internet gateway phải được tạo ra trước để có public subnet đặt nat gateway
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associate Private Subnets with Private Route Table
# resource "aws_route_table_association" "private" {
#   count          = length(var.private_subnet)
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private.id
# }

# Chỉ web và app cần igw
resource "aws_route_table_association" "private_web_app" {
  count          = 4
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "db_private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-db-private-rt"
  }
}

resource "aws_route_table_association" "db_private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index + 4].id
  route_table_id = aws_route_table.db_private.id
}

# --- VPC Flow Logs Configuration ---
# 1. Tạo một CloudWatch Log Group để lưu trữ logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}"
  retention_in_days = 7 
}

# 2. Bật Flow Logs cho VPC, chỉ định nơi lưu và quyền sử dụng
resource "aws_flow_log" "main" {
  # IAM Role mà Flow Logs sẽ sử dụng để có quyền ghi vào CloudWatch
  iam_role_arn    = var.flow_log_iam_role_arn

  # Nơi chứa log (Log Group đã tạo ở trên)
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  
  # Loại traffic cần ghi lại: ALL (tất cả), ACCEPT (chỉ traffic được phép), REJECT (chỉ traffic bị từ chối)
  traffic_type    = "ALL"

  # ID của VPC cần bật Flow Logs
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-flow-log"
  }
}

# --- VPC Endpoints for AWS Systems Manager (SSM) ---

# Endpoint này cần thiết cho chính dịch vụ SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for i in range(length(var.availability_zones)) : aws_subnet.private[i].id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
}

# Endpoint này cần thiết cho các phiên EC2 Messages (dùng cho Session Manager)
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for i in range(length(var.availability_zones)) : aws_subnet.private[i].id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
}

# Endpoint này cần thiết cho việc thu thập dữ liệu của SSM
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for i in range(length(var.availability_zones)) : aws_subnet.private[i].id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
}

# --- Security Group for VPC Endpoints ---
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "${var.project_name}-vpc-endpoint-sg"
  description = "Allow HTTPS traffic to VPC endpoints"
  vpc_id      = aws_vpc.main.id

  # Cho phép tất cả traffic HTTPS từ bên trong VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Chỉ cho phép từ trong VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-vpc-endpoint-sg"
  }
}

# Thêm data source để lấy region hiện tại
data "aws_region" "current" {}