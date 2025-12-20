# ========================================
# NETWORKING MODULE - VARIABLES
# ========================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 32
    error_message = "Project name must be between 1 and 32 characters"
  }
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability"
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required"
  }
}

variable "private_web_subnet_cidrs" {
  description = "CIDR blocks for private web subnets"
  type        = list(string)
  
  validation {
    condition     = length(var.private_web_subnet_cidrs) >= 2
    error_message = "At least 2 private web subnets are required"
  }
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app subnets"
  type        = list(string)
  
  validation {
    condition     = length(var.private_app_subnet_cidrs) >= 2
    error_message = "At least 2 private app subnets are required"
  }
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
  
  validation {
    condition     = length(var.private_db_subnet_cidrs) >= 2
    error_message = "At least 2 private database subnets are required"
  }
}

variable "flow_log_iam_role_arn" {
  description = "IAM role ARN for VPC Flow Logs"
  type        = string
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for SSM"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
