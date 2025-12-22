variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "web_ami_id" {
  description = "AMI ID for web"
  type        = string
  default     = "ami-039c813819c142011"
}

variable "app_ami_id" {
  description = "AMI ID for app"
  type        = string
  default     = "ami-0e7d3158cc33a26b2"  # Packer v1.0
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
  description = "Security group ID for Web"
  type        = string
}

variable "app_sg_id" {
  description = "Security group ID for App"
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

# ===== Docker Deployment Variables =====
variable "ecr_registry" {
  description = "ECR registry URL"
  type        = string
  default     = "120915930136.dkr.ecr.ap-southeast-2.amazonaws.com"
}

variable "frontend_image_tag" {
  description = "Docker image tag for frontend"
  type        = string
  default     = "latest"
}

variable "backend_image_tag" {
  description = "Docker image tag for backend"
  type        = string
  default     = "latest"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "use_docker_deployment" {
  description = "Use Docker-based deployment instead of traditional AMI deployment"
  type        = bool
  default     = true
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

variable "private_app_subnet_ids" {
  description = "List of private app subnet IDs"
  type        = list(string)
}

# ===== BLUE TARGET GROUPS =====
variable "web_target_group_blue_arn" {
  description = "ARN of the web blue target group"
  type        = string
}

variable "app_target_group_blue_arn" {
  description = "ARN of the app blue target group"
  type        = string
}

# ===== GREEN TARGET GROUPS =====
variable "web_target_group_green_arn" {
  description = "ARN of the web green target group"
  type        = string
}

variable "app_target_group_green_arn" {
  description = "ARN of the app green target group"
  type        = string
}

variable "internal_alb_dns_name" {
  description = "DNS name of the internal ALB"
  type        = string
}

variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type = string
}

variable "ec2_instance_profile_name" {
  description = "The name of the IAM instance profile for EC2"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
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

# ===== AMI CONFIGURATIONS =====
variable "web_ami_id_green" {
  description = "AMI ID for web tier green environment (optional, defaults to web_ami_id)"
  type        = string
  default     = ""
}

variable "app_ami_id_green" {
  description = "AMI ID for app tier green environment (optional, defaults to app_ami_id)"
  type        = string
  default     = ""
}

