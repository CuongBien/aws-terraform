# ========================================
# COMPUTE - WEB TIER MODULE - VARIABLES
# ========================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "web_ami_id" {
  description = "AMI ID for web tier blue environment"
  type        = string
  default     = "ami-039c813819c142011"
}

variable "web_ami_id_green" {
  description = "AMI ID for web tier green environment (optional, defaults to web_ami_id)"
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

variable "web_sg_id" {
  description = "Security group ID for Web tier"
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

variable "private_web_subnet_ids" {
  description = "List of private web subnet IDs"
  type        = list(string)
}

variable "web_target_group_blue_arn" {
  description = "ARN of the web blue target group"
  type        = string
}

variable "web_target_group_green_arn" {
  description = "ARN of the web green target group"
  type        = string
}

variable "internal_alb_dns_name" {
  description = "DNS name of the internal ALB (for reverse proxy)"
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
