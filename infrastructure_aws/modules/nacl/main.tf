###########################################
# NACL hoạt động ở tầng 4 (Transport Layer)
###########################################

#================ Public Subnet ================

resource "aws_network_acl" "public" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-public-nacl"
  }
}

# --- Allow all internal VPC traffic ---
resource "aws_network_acl_rule" "public_inbound_from_vpc" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 50
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

resource "aws_network_acl_rule" "public_outbound_to_vpc" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 50
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# --- INBOUND RULES ---
# SSH
resource "aws_network_acl_rule" "public_inbound_ssh" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

# HTTP
resource "aws_network_acl_rule" "public_inbound_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# HTTPS
resource "aws_network_acl_rule" "public_inbound_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Ephemeral ports (internet -> ALB)
resource "aws_network_acl_rule" "public_inbound_ephemeral_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# --- OUTBOUND RULES ---
# SSH response
resource "aws_network_acl_rule" "public_outbound_ssh" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# ALB -> Web EC2
resource "aws_network_acl_rule" "public_outbound_http_web" {
  count          = length(var.web_private_subnet_cidrs)
  network_acl_id = aws_network_acl.public.id
  rule_number    = 210 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.web_private_subnet_cidrs[count.index]
  from_port      = 80
  to_port        = 80
}

# NAT / ALB -> Internet
resource "aws_network_acl_rule" "public_outbound_http_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 220
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_outbound_https_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 230
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Outbound ephemeral
resource "aws_network_acl_rule" "public_outbound_ephemeral_internet" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 240
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_association" "public" {
  count          = length(var.public_subnet_ids)
  network_acl_id = aws_network_acl.public.id
  subnet_id      = var.public_subnet_ids[count.index]
}

#================ Web Private Subnet ================

resource "aws_network_acl" "web_private" {
  vpc_id = var.vpc_id
  tags = { Name = "${var.project_name}-web-private-nacl" }
}

# Allow internal VPC
resource "aws_network_acl_rule" "web_private_inbound_from_vpc" {
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 50
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

resource "aws_network_acl_rule" "web_private_outbound_to_vpc" {
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 50
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# Inbound
resource "aws_network_acl_rule" "web_inbound_http" {
  count          = length(var.public_subnet_cidrs)
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 150 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.public_subnet_cidrs[count.index]
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "web_inbound_ephemeral_internet" {
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 160
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound
resource "aws_network_acl_rule" "web_outbound_http_internet" {
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 250
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "web_outbound_https_internet" {
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 260
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "web_outbound_ephemeral_nat" {
  network_acl_id = aws_network_acl.web_private.id
  rule_number    = 270
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_association" "web_private" {
  count          = length(var.private_web_subnet_ids)
  network_acl_id = aws_network_acl.web_private.id
  subnet_id      = var.private_web_subnet_ids[count.index]
}

#================ App Private Subnet ================

resource "aws_network_acl" "app_private" {
  vpc_id = var.vpc_id
  tags = { Name = "${var.project_name}-app-private-nacl" }
}

# Allow internal VPC
resource "aws_network_acl_rule" "app_private_inbound_from_vpc" {
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 50
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

resource "aws_network_acl_rule" "app_private_outbound_to_vpc" {
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 50
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# Inbound
resource "aws_network_acl_rule" "app_inbound_web" {
  count          = length(var.web_private_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 300 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.web_private_subnet_cidrs[count.index]
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "app_inbound_ephemeral_rds" {
  count          = length(var.db_private_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 310 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_private_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "app_inbound_ephemeral_internet" {
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 320
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Outbound
resource "aws_network_acl_rule" "app_outbound_rds" {
  count          = length(var.db_private_subnet_cidrs)
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 350 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.db_private_subnet_cidrs[count.index]
  from_port      = 3306
  to_port        = 3306
}

resource "aws_network_acl_rule" "app_outbound_http_nat" {
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 360
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "app_outbound_https_nat" {
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 370
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "app_outbound_ephemeral_internet" {
  network_acl_id = aws_network_acl.app_private.id
  rule_number    = 380
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_association" "app_private" {
  count          = length(var.private_app_subnet_ids)
  network_acl_id = aws_network_acl.app_private.id
  subnet_id      = var.private_app_subnet_ids[count.index]
}

#================ DB Private Subnet ================

resource "aws_network_acl" "db_private" {
  vpc_id = var.vpc_id
  tags = { Name = "${var.project_name}-db-private-nacl" }
}

# Allow internal VPC
resource "aws_network_acl_rule" "db_private_inbound_from_vpc" {
  network_acl_id = aws_network_acl.db_private.id
  rule_number    = 50
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

resource "aws_network_acl_rule" "db_private_outbound_to_vpc" {
  network_acl_id = aws_network_acl.db_private.id
  rule_number    = 50
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr_block
}

# Inbound
resource "aws_network_acl_rule" "db_inbound_app" {
  count          = length(var.app_private_subnet_cidrs)
  network_acl_id = aws_network_acl.db_private.id
  rule_number    = 400 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_private_subnet_cidrs[count.index]
  from_port      = 3306
  to_port        = 3306
}

# Outbound
resource "aws_network_acl_rule" "db_outbound_ephemeral_app" {
  count          = length(var.app_private_subnet_cidrs)
  network_acl_id = aws_network_acl.db_private.id
  rule_number    = 450 + count.index
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.app_private_subnet_cidrs[count.index]
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_association" "db_private" {
  count          = length(var.private_db_subnet_ids)
  network_acl_id = aws_network_acl.db_private.id
  subnet_id      = var.private_db_subnet_ids[count.index]
}
