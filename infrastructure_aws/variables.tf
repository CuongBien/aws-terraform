# ========================================
# ROOT VARIABLES
# ========================================

# ===== PROJECT CONFIGURATION =====

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
  default     = "pbl4-three-tier"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# ===== NETWORKING CONFIGURATION =====

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks (web, app, db tiers)"
  type        = list(string)
  default = [
    "10.0.11.0/24", "10.0.12.0/24", # Web tier
    "10.0.21.0/24", "10.0.22.0/24", # App tier
    "10.0.31.0/24", "10.0.32.0/24"  # DB tier
  ]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_ssm_vpc_endpoint" {
  description = "Enable VPC endpoints for SSM (Systems Manager)"
  type        = bool
  default     = true
}

# ===== DOCKER DEPLOYMENT CONFIGURATION =====

variable "use_docker_deployment" {
  description = "Use Docker-based deployment instead of traditional AMI deployment"
  type        = bool
  default     = true  # Always use Docker
}

variable "ecr_registry" {
  description = "ECR registry URL"
  type        = string
  default     = "120915930136.dkr.ecr.ap-southeast-2.amazonaws.com"
}

variable "frontend_image_tag" {
  description = "Docker image tag for frontend (e.g., v1.0, latest)"
  type        = string
  default     = "latest"  # Always pull latest
}

variable "backend_image_tag" {
  description = "Docker image tag for backend (e.g., v1.0, latest)"
  type        = string
  default     = "latest"  # Always pull latest
}

# ===== EC2 CONFIGURATION =====

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = "pbl4-three-tier-key"
}

# Web Tier
variable "web_ami_id_blue" {
  description = "AMI ID for web tier blue environment"
  type        = string
  default     = "ami-0cf771f557cd2c733"  # Docker base
}

variable "web_ami_id_green" {
  description = "AMI ID for web tier green environment (optional)"
  type        = string
  default     = "ami-0cf771f557cd2c733"  # Same as blue for Docker deployment
}

variable "web_instance_type" {
  description = "Instance type for web tier"
  type        = string
  default     = "t3.micro"
}

variable "web_min_size" {
  description = "Minimum size of web ASG"
  type        = number
  default     = 1
}

variable "web_max_size" {
  description = "Maximum size of web ASG"
  type        = number
  default     = 3
}

variable "web_desired_capacity" {
  description = "Desired capacity of web ASG"
  type        = number
  default     = 1
}

# App Tier
variable "app_ami_id_blue" {
  description = "AMI ID for app tier blue environment"
  type        = string
  default     = "ami-0cb5ffeec8df16819"  # Docker base
}

variable "app_ami_id_green" {
  description = "AMI ID for app tier green environment (optional)"
  type        = string
  default     = "ami-0cb5ffeec8df16819"  # Same as blue for Docker deployment
}

variable "app_instance_type" {
  description = "Instance type for app tier"
  type        = string
  default     = "t3.micro"
}

variable "app_min_size" {
  description = "Minimum size of app ASG"
  type        = number
  default     = 1
}

variable "app_max_size" {
  description = "Maximum size of app ASG"
  type        = number
  default     = 3
}

variable "app_desired_capacity" {
  description = "Desired capacity of app ASG"
  type        = number
  default     = 1
}

# Bastion Host
variable "bastion_ami_id" {
  description = "AMI ID for bastion host (if empty, uses latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_root_volume_size" {
  description = "Size of bastion root volume in GB"
  type        = number
  default     = 30
}

variable "bastion_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = ["117.2.255.206/32"]
}

# ===== DATABASE CONFIGURATION =====cd 

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "ecommerce"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = true
}

# ===== BLUE/GREEN DEPLOYMENT =====

variable "traffic_distribution_blue" {
  description = "Percentage of traffic to blue environment (0-100)"
  type        = number
  default     = 100
}

variable "traffic_distribution_green" {
  description = "Percentage of traffic to green environment (0-100)"
  type        = number
  default     = 0
}

variable "enable_blue_env" {
  description = "Enable blue environment (instances running)"
  type        = bool
  default     = true
}

variable "enable_green_env" {
  description = "Enable green environment (instances running)"
  type        = bool
  default     = true  # Enable for canary deployment
}

# ===== MONITORING CONFIGURATION =====

variable "alarm_email_endpoints" {
  description = "List of email addresses to receive CloudWatch alarms"
  type        = list(string)
  default     = ["puppy261205@gmail.com"]
}
