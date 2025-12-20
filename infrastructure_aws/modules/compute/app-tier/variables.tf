# ========================================
# COMPUTE - APP TIER MODULE - VARIABLES
# ========================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "app_ami_id" {
  description = "AMI ID for app tier blue environment"
  type        = string
  default     = "ami-0540d3917795ab713"
}

variable "app_ami_id_green" {
  description = "AMI ID for app tier green environment (optional, defaults to app_ami_id)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "app_sg_id" {
  description = "Security group ID for App tier"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "The name of the IAM instance profile for EC2"
  type        = string
}

variable "min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 1
}

variable "private_app_subnet_ids" {
  description = "List of private app subnet IDs"
  type        = list(string)
}

variable "app_target_group_blue_arn" {
  description = "ARN of the app blue target group"
  type        = string
}

variable "app_target_group_green_arn" {
  description = "ARN of the app green target group"
  type        = string
}

variable "db_host" {
  description = "Database host endpoint"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the public ALB (for shop_url in config)"
  type        = string
}

# ===== BLUE/GREEN ENVIRONMENT CONTROL =====

variable "enable_blue_env" {
  description = "Enable blue environment (true = running, false = scaled to 0)"
  type        = bool
  default     = true
}

variable "enable_green_env" {
  description = "Enable green environment (true = running, false = scaled to 0)"
  type        = bool
  default     = false
}
