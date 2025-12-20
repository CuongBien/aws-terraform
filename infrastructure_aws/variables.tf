variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "pbl4-three-tier"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.21.0/24", "10.0.22.0/24", "10.0.31.0/24", "10.0.32.0/24"]
}

variable "db_username" {
  description = "DB master username"
  type        = string
}

variable "db_password" {
  description = "DB master password"
  type        = string
  sensitive   = true
}

variable "key_pair_name" {
  description = "EC2 key pair name"
  type        = string
  default     = "pbl4-three-tier-key"
}

variable "my_ip" {
  description = "Your home or office IP address for SSH access"
  type        = string
  default     = "117.3.54.230/32" 
}

# variable "project_name" {
#   description = "Name of the project"
#   type        = string
# }

# variable "vpc_id" {
#   description = "ID of the VPC"
#   type        = string
# }

# variable "my_ip" {
#   description = "IP address for SSH access"
#   type        = string
# }