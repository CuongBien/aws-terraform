# ========================================
# CORE - SECURITY MODULE
# ========================================
# Security Groups for all tiers: ALB, Web, App, Database, Bastion
# ========================================

# ========================================
# PUBLIC ALB SECURITY GROUP
# ========================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Public ALB"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb-sg"
      Tier = "edge"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#tfsec:ignore:aws-ec2-no-public-ingress-sgr # Public-facing ALB requires internet access
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet"
}

#tfsec:ignore:aws-ec2-no-public-ingress-sgr # Public-facing ALB requires internet access
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr # ALB needs outbound to target groups
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
}

# ========================================
# INTERNAL ALB SECURITY GROUP
# ========================================

resource "aws_security_group" "internal_alb" {
  name        = "${var.project_name}-internal-alb-sg"
  description = "Security group for Internal ALB"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-internal-alb-sg"
      Tier = "internal"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "internal_alb_ingress_from_web" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.internal_alb.id
  description              = "Allow HTTP/HTTPS from Web tier"
}

resource "aws_security_group_rule" "internal_alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.internal_alb.id
  description       = "Allow all outbound"
}

# ========================================
# WEB TIER SECURITY GROUP
# ========================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for Web tier EC2 instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-web-sg"
      Tier = "web"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.web.id
  description              = "Allow HTTP/HTTPS from Public ALB"
}

resource "aws_security_group_rule" "web_ingress_8080_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.web.id
  description              = "Allow port 8080 from Public ALB for Docker containers"
}

resource "aws_security_group_rule" "web_ingress_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.web.id
  description              = "Allow SSH from Bastion"
}

resource "aws_security_group_rule" "web_ingress_http_from_bastion" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.web.id
  description              = "Allow HTTP from Bastion for testing"
}

resource "aws_security_group_rule" "web_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound"
}

# ========================================
# APP TIER SECURITY GROUP
# ========================================

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for App tier EC2 instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-sg"
      Tier = "app"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "app_ingress_from_internal_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_alb.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow HTTP/HTTPS from Internal ALB"
}

resource "aws_security_group_rule" "app_ingress_8080_from_internal_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_alb.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow port 8080 from Internal ALB for Docker containers"
}

resource "aws_security_group_rule" "app_ingress_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow SSH from Bastion"
}

resource "aws_security_group_rule" "app_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound"
}

# ========================================
# DATABASE SECURITY GROUP
# ========================================

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for RDS instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-db-sg"
      Tier = "database"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "db_ingress_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
  description              = "Allow MySQL from App tier"
}

resource "aws_security_group_rule" "db_ingress_from_bastion" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.db.id
  description              = "Allow MySQL from Bastion for SSH tunnel"
}

resource "aws_security_group_rule" "db_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db.id
  description       = "Allow all outbound"
}

# ========================================
# BASTION SECURITY GROUP
# ========================================

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-bastion-sg"
      Tier = "management"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.bastion_allowed_cidrs
  security_group_id = aws_security_group.bastion.id
  description       = "Allow SSH from allowed IPs"
}

resource "aws_security_group_rule" "bastion_egress_to_vpc" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow all outbound within VPC"
}

resource "aws_security_group_rule" "bastion_egress_to_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow all outbound to internet"
}
