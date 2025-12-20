# Terraform configuration for Three-Tier Architecture

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name      = var.project_name
  availability_zones = var.availability_zones

  public_subnet     = var.public_subnet_cidrs
  private_subnet    = var.private_subnet_cidrs

  flow_log_iam_role_arn = aws_iam_role.vpc_flow_logs_role.arn
}

# # Security Module
# module "security" {
#   source = "./modules/security"

#   project_name = var.project_name
#   vpc_id       = module.vpc.vpc_id
#   my_ip        = var.my_ip
# }

# ALB Module with Blue/Green support
module "alb" {
  source = "./modules/alb"

  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  alb_sg_id            = aws_security_group.alb.id
  internal_alb_sg_id   = aws_security_group.internal_alb.id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_web_subnet_ids = module.vpc.private_web_subnet_ids

  sns_topic_arn        = aws_sns_topic.alarms_topic.arn
  
  # Blue/Green traffic distribution
  traffic_distribution_blue  = var.traffic_distribution_blue
  traffic_distribution_green = var.traffic_distribution_green
  
  # certificate_arn      = aws_acm_certificate.cert.arn
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  db_sg_id              = aws_security_group.db.id

  # Required: set these
  db_username = var.db_username
  db_password = var.db_password

}
# ASG Module with Blue/Green support
module "asg" {
  source = "./modules/asg"

  project_name              = var.project_name
  web_sg_id                 = aws_security_group.web.id
  app_sg_id                 = aws_security_group.app.id
  private_web_subnet_ids    = module.vpc.private_web_subnet_ids
  private_app_subnet_ids    = module.vpc.private_app_subnet_ids
  
  # Blue Target Groups
  web_target_group_blue_arn = module.alb.web_target_group_blue_arn
  app_target_group_blue_arn = module.alb.app_target_group_blue_arn
  
  # Green Target Groups
  web_target_group_green_arn = module.alb.web_target_group_green_arn
  app_target_group_green_arn = module.alb.app_target_group_green_arn
  
  alb_dns_name              = module.alb.alb_dns_name
  internal_alb_dns_name     = module.alb.internal_alb_dns_name
  
  db_host                   = module.rds.db_endpoint
  db_username               = var.db_username
  db_password               = var.db_password
  db_name                   = module.rds.db_name

  ec2_instance_profile_name = aws_iam_instance_profile.ec2_cloudwatch_agent_instance_profile.name

  # Key pair for EC2 instances (optional)
  key_pair_name = var.key_pair_name
  
  # Blue/Green environment control
  enable_blue_env  = var.enable_blue_env
  enable_green_env = var.enable_green_env
  
  # AMI configurations (optional - for testing new AMIs)
  web_ami_id_green = var.web_ami_id_green
  app_ami_id_green = var.app_ami_id_green
}

module "nacl" {
  source = "./modules/nacl"

  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_web_subnet_ids = module.vpc.private_web_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  private_db_subnet_ids = module.vpc.private_db_subnet_ids
  vpc_cidr_block = module.vpc.vpc_cidr_block
  
  public_subnet_cidrs = var.public_subnet_cidrs
  web_private_subnet_cidrs = slice(var.private_subnet_cidrs, 0, 2)
  app_private_subnet_cidrs = slice(var.private_subnet_cidrs, 2, 4)
  db_private_subnet_cidrs = slice(var.private_subnet_cidrs, 4, 6)
}

# # --- SNS Topic for CloudWatch Alarms ---

# Tạo một kênh thông báo SNS
resource "aws_sns_topic" "alarms_topic" {
  name = "${var.project_name}-alarms-topic"
  kms_master_key_id = aws_kms_key.sns_key.arn
}

# Đăng ký email
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alarms_topic.arn
  protocol  = "email"
  endpoint  = "puppy261205@gmail.com" 
}

# resource "aws_acm_certificate" "cert" {
#   domain_name       = "thuongmaidientu.com"
#   validation_method = "DNS"
# }

# modules/security/main.tf

# ===================================================================
# 1. TẠO CÁC SECURITY GROUP "TRỐNG"
# ===================================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Public ALB"
  vpc_id      = module.vpc.vpc_id
  tags        = { Name = "${var.project_name}-alb-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "internal_alb" {
  name        = "${var.project_name}-internal-alb-sg"
  description = "Security group for Internal ALB"
  vpc_id      = module.vpc.vpc_id
  tags        = { Name = "${var.project_name}-internal-alb-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for Web Tier EC2 instances"
  vpc_id      = module.vpc.vpc_id
  tags        = { Name = "${var.project_name}-web-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for App Tier EC2 instances"
  vpc_id      = module.vpc.vpc_id
  tags        = { Name = "${var.project_name}-app-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for RDS instances"
  vpc_id      = module.vpc.vpc_id
  tags        = { Name = "${var.project_name}-db-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for Bastion Host"
  vpc_id      = module.vpc.vpc_id
  tags        = { Name = "${var.project_name}-bastion-sg" }

  lifecycle {
    create_before_destroy = true
  }
}


# ===================================================================
# 2. TẠO CÁC LUẬT (RULES) RIÊNG LẺ VÀ GẮN VÀO GROUP
# ===================================================================

# --- Luật cho Public ALB ---
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from anywhere"
}
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from anywhere"
}
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"
}

# --- Luật cho Web Tier ---
resource "aws_security_group_rule" "web_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80 # Hoặc 0 nếu bạn muốn cho phép cả 80/443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.web.id
  description              = "Allow HTTP/S from Public ALB"
}
resource "aws_security_group_rule" "web_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"
}

# --- Luật cho Internal ALB ---
resource "aws_security_group_rule" "internal_alb_ingress_from_web" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  security_group_id        = aws_security_group.internal_alb.id
  description              = "Allow HTTP/S from Web Tier"
}
resource "aws_security_group_rule" "internal_alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.internal_alb.id
  description       = "Allow all outbound traffic"
}

# --- Luật cho App Tier ---
resource "aws_security_group_rule" "app_ingress_from_internal_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.internal_alb.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow HTTP/S from Internal ALB"
}
resource "aws_security_group_rule" "app_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
  description       = "Allow all outbound traffic"
}

# --- Luật cho Database ---
resource "aws_security_group_rule" "db_ingress_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
  description              = "Allow MySQL from App Tier"
}
# (Bạn có thể thêm luật egress cho DB nếu muốn siết chặt, nhưng egress-all cũng được)

# --- Luật cho Bastion Host ---
resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.my_ip]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow SSH from my IP"
}
resource "aws_security_group_rule" "bastion_egress_to_vpc" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow all outbound traffic within the VPC"
}
resource "aws_security_group_rule" "bastion_egress_to_internet" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow all outbound traffic to the Internet"
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

resource "aws_security_group_rule" "app_ingress_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.app.id
  description              = "Allow SSH from Bastion"
}

resource "aws_security_group_rule" "web_ingress_http_from_bastion" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.web.id
  description              = "Allow HTTP from Bastion for testing Web instances"
}