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
  default     = "ami-0540d3917795ab713"
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

variable "web_target_group_arn" {
  description = "ARN of the web target group"
  type        = string
}

variable "app_target_group_arn" {
  description = "ARN of the app target group"
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

