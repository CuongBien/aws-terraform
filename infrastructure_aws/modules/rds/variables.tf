variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "List of private DB subnet IDs"
  type        = list(string)
}

variable "db_instance_class" {
  description = "DB instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "DB allocated storage in GB"
  type        = number
  default     = 20
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

variable "db_name" {
  description = "Initial DB name"
  type        = string
  default     = "hello_world" # tùy chỉnh (dữ liệu tạm thời test)
}

variable "db_sg_id" {
  description = "DB security group ID"
  type        = string
}
