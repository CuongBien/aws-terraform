# ========================================
# SECURITY MODULE - VARIABLES
# ========================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "bastion_allowed_cidrs" {
  description = "List of CIDR blocks allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  
  validation {
    condition     = length(var.bastion_allowed_cidrs) > 0
    error_message = "At least one CIDR block must be specified for bastion access"
  }
}

variable "db_port" {
  description = "Database port (default MySQL 3306)"
  type        = number
  default     = 3306
  
  validation {
    condition     = var.db_port > 0 && var.db_port <= 65535
    error_message = "Database port must be between 1 and 65535"
  }
}

variable "enable_internal_alb" {
  description = "Enable internal ALB security group"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all security groups"
  type        = map(string)
  default     = {}
}
