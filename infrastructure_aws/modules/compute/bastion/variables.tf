# ========================================
# COMPUTE - BASTION MODULE - VARIABLES
# ========================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "bastion_ami_id" {
  description = "AMI ID for bastion host (if empty, uses latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type for bastion"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) > 0
    error_message = "At least one public subnet ID is required for bastion host."
  }
}

variable "bastion_sg_id" {
  description = "Security group ID for bastion host"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "The name of the IAM instance profile for EC2"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 30

  validation {
    condition     = var.root_volume_size >= 30 && var.root_volume_size <= 100
    error_message = "Root volume size must be between 30 and 100 GB."
  }
}
