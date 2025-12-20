# ========================================
# EDGE - ALB MODULE - VARIABLES
# ========================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "alb_sg_id" {
  description = "Security group ID for external ALB"
  type        = string
}

variable "internal_alb_sg_id" {
  description = "Security group ID for internal ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for external ALB"
  type        = list(string)
}

variable "private_web_subnet_ids" {
  description = "List of private web subnet IDs for internal ALB"
  type        = list(string)
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  type        = string
}

# ===== BLUE/GREEN DEPLOYMENT VARIABLES =====

variable "traffic_distribution_blue" {
  description = "Traffic weight for blue environment (0-100)"
  type        = number
  default     = 100

  validation {
    condition     = var.traffic_distribution_blue >= 0 && var.traffic_distribution_blue <= 100
    error_message = "Traffic distribution must be between 0 and 100."
  }
}

variable "traffic_distribution_green" {
  description = "Traffic weight for green environment (0-100)"
  type        = number
  default     = 0

  validation {
    condition     = var.traffic_distribution_green >= 0 && var.traffic_distribution_green <= 100
    error_message = "Traffic distribution must be between 0 and 100."
  }
}
