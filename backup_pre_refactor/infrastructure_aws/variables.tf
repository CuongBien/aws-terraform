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
  default     = "171.225.184.178/32" 
}

# ===== BLUE/GREEN DEPLOYMENT VARIABLES =====
variable "traffic_distribution_blue" {
  description = "Percentage of traffic to blue environment (0-100)"
  type        = number
  default     = 100  # 100% traffic đến blue
}

variable "traffic_distribution_green" {
  description = "Percentage of traffic to green environment (0-100)"
  type        = number
  default     = 0    # 0% traffic đến green
}

variable "enable_blue_env" {
  description = "Enable blue environment (instances running)"
  type        = bool
  default     = true  # Blue đang chạy
}

variable "enable_green_env" {
  description = "Enable green environment (instances running)"
  type        = bool
  default     = false # Green không chạy
}

variable "web_ami_id_green" {
  description = "AMI ID for green web tier (optional)"
  type        = string
  default     = ""
}

variable "app_ami_id_green" {
  description = "AMI ID for green app tier (optional)"
  type        = string
  default     = ""
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