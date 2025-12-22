# ========================================
# TERRAFORM CONFIGURATION - THREE-TIER E-COMMERCE ARCHITECTURE
# ========================================
# Modular infrastructure with Blue/Green deployment support
# ========================================

# ===== CORE MODULES =====

# Networking - VPC, Subnets, NAT Gateway, Internet Gateway
module "networking" {
  source = "./modules/core/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnet_cidrs        = var.public_subnet_cidrs
  private_web_subnet_cidrs   = local.web_subnet_cidrs
  private_app_subnet_cidrs   = local.app_subnet_cidrs
  private_db_subnet_cidrs    = local.db_subnet_cidrs

  flow_log_iam_role_arn = aws_iam_role.vpc_flow_logs_role.arn
  enable_vpc_endpoints  = var.enable_ssm_vpc_endpoint

  tags = local.common_tags
}

# Security - All Security Groups and Rules
module "security" {
  source = "./modules/core/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = module.networking.vpc_cidr

  # Bastion access configuration
  bastion_allowed_cidrs = var.bastion_allowed_cidrs

  tags = local.common_tags
}

# Monitoring - CloudWatch, SNS for alarms
module "monitoring" {
  source = "./modules/core/monitoring"

  project_name           = var.project_name
  environment            = var.environment
  alarm_email_endpoints  = var.alarm_email_endpoints
  kms_key_id            = aws_kms_key.sns_key.arn

  tags = local.common_tags
}

# ===== DATA MODULES =====

# RDS - MySQL database
module "rds" {
  source = "./modules/data/rds"

  project_name          = var.project_name
  private_db_subnet_ids = module.networking.private_db_subnet_ids
  db_sg_id              = module.security.db_sg_id

  db_engine_version       = var.db_engine_version
  db_instance_class       = var.db_instance_class
  db_allocated_storage    = var.db_allocated_storage
  db_username             = var.db_username
  db_password             = var.db_password
  db_name                 = var.db_name
  multi_az                = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  backup_window           = var.db_backup_window
  maintenance_window      = var.db_maintenance_window
  deletion_protection     = var.db_deletion_protection
  skip_final_snapshot     = var.db_skip_final_snapshot
}

# ===== EDGE MODULES =====

# Application Load Balancer - Public and Internal ALBs
module "alb" {
  source = "./modules/edge/alb"

  project_name           = var.project_name
  vpc_id                 = module.networking.vpc_id
  alb_sg_id              = module.security.alb_sg_id
  internal_alb_sg_id     = module.security.internal_alb_sg_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_web_subnet_ids = module.networking.private_web_subnet_ids

  sns_topic_arn = module.monitoring.sns_topic_arn

  # Blue/Green traffic distribution
  traffic_distribution_blue  = var.traffic_distribution_blue
  traffic_distribution_green = var.traffic_distribution_green
}

# ===== COMPUTE MODULES =====

# Web Tier - Nginx reverse proxy servers
module "web_tier" {
  source = "./modules/compute/web-tier"

  project_name              = var.project_name
  web_ami_id                = var.web_ami_id_blue
  web_ami_id_green          = var.web_ami_id_green
  instance_type             = var.web_instance_type
  key_pair_name             = var.key_pair_name
  web_sg_id                 = module.security.web_sg_id
  ec2_instance_profile_name = aws_iam_instance_profile.ec2_cloudwatch_agent_instance_profile.name

  min_size         = var.web_min_size
  max_size         = var.web_max_size
  desired_capacity = var.web_desired_capacity

  private_web_subnet_ids     = module.networking.private_web_subnet_ids
  web_target_group_blue_arn  = module.alb.web_target_group_blue_arn
  web_target_group_green_arn = module.alb.web_target_group_green_arn
  internal_alb_dns_name      = module.alb.internal_alb_dns_name

  enable_blue_env  = var.enable_blue_env
  enable_green_env = var.enable_green_env
}

# App Tier - Application servers (OpenCart)
module "app_tier" {
  source = "./modules/compute/app-tier"

  project_name              = var.project_name
  app_ami_id                = var.app_ami_id_blue
  app_ami_id_green          = var.app_ami_id_green
  instance_type             = var.app_instance_type
  key_pair_name             = var.key_pair_name
  app_sg_id                 = module.security.app_sg_id
  ec2_instance_profile_name = aws_iam_instance_profile.ec2_cloudwatch_agent_instance_profile.name

  min_size         = var.app_min_size
  max_size         = var.app_max_size
  desired_capacity = var.app_desired_capacity

  private_app_subnet_ids     = module.networking.private_app_subnet_ids
  app_target_group_blue_arn  = module.alb.app_target_group_blue_arn
  app_target_group_green_arn = module.alb.app_target_group_green_arn

  db_host     = module.rds.db_endpoint
  db_username = var.db_username
  db_password = var.db_password
  db_name     = module.rds.db_name

  alb_dns_name = module.alb.alb_dns_name

  enable_blue_env  = var.enable_blue_env
  enable_green_env = var.enable_green_env
}

# Bastion Host - SSH jump server
module "bastion" {
  source = "./modules/compute/bastion"

  project_name              = var.project_name
  bastion_ami_id            = var.bastion_ami_id
  instance_type             = var.bastion_instance_type
  key_pair_name             = var.key_pair_name
  public_subnet_ids         = module.networking.public_subnet_ids
  bastion_sg_id             = module.security.bastion_sg_id
  ec2_instance_profile_name = aws_iam_instance_profile.ec2_cloudwatch_agent_instance_profile.name
  root_volume_size          = var.bastion_root_volume_size
}

# ===== NETWORK ACLs =====

module "nacl" {
  source = "./modules/nacl"

  project_name           = var.project_name
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_web_subnet_ids = module.networking.private_web_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  private_db_subnet_ids  = module.networking.private_db_subnet_ids
  vpc_cidr_block         = module.networking.vpc_cidr

  public_subnet_cidrs      = var.public_subnet_cidrs
  web_private_subnet_cidrs = local.web_subnet_cidrs
  app_private_subnet_cidrs = local.app_subnet_cidrs
  db_private_subnet_cidrs  = local.db_subnet_cidrs
}
