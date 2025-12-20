# ========================================
# ROOT OUTPUTS
# ========================================

# ===== NETWORKING OUTPUTS =====

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_web_subnet_ids" {
  description = "List of private web subnet IDs"
  value       = module.networking.private_web_subnet_ids
}

output "private_app_subnet_ids" {
  description = "List of private app subnet IDs"
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = module.networking.private_db_subnet_ids
}

# ===== LOAD BALANCER OUTPUTS =====

output "alb_dns_name" {
  description = "DNS name of the public ALB"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "URL of the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal ALB"
  value       = module.alb.internal_alb_dns_name
}

# ===== COMPUTE OUTPUTS =====

output "web_asg_blue_name" {
  description = "Name of the web blue ASG"
  value       = module.web_tier.web_asg_blue_name
}

output "web_asg_green_name" {
  description = "Name of the web green ASG"
  value       = module.web_tier.web_asg_green_name
}

output "app_asg_blue_name" {
  description = "Name of the app blue ASG"
  value       = module.app_tier.app_asg_blue_name
}

output "app_asg_green_name" {
  description = "Name of the app green ASG"
  value       = module.app_tier.app_asg_green_name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i ${var.key_pair_name}.pem ec2-user@${module.bastion.bastion_public_ip}"
}

# ===== DATABASE OUTPUTS =====

output "db_endpoint" {
  description = "RDS endpoint address"
  value       = module.rds.db_endpoint
}

output "db_name" {
  description = "Database name"
  value       = module.rds.db_name
}

# ===== DEPLOYMENT STATE OUTPUTS =====

output "deployment_state" {
  description = "Current Blue/Green deployment state"
  value       = local.deployment_state
}

output "traffic_distribution" {
  description = "Current traffic distribution"
  value = {
    blue  = var.traffic_distribution_blue
    green = var.traffic_distribution_green
  }
}

# ===== MONITORING OUTPUTS =====

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alarms"
  value       = module.monitoring.sns_topic_arn
}
