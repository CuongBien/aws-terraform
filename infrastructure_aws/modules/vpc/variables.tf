variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "public_subnet" {
  type = list(string)
}

variable "private_subnet" {
  type        = list(string)
}

variable "flow_log_iam_role_arn" {
  description = "The ARN of the IAM role for VPC Flow Logs"
  type        = string
}