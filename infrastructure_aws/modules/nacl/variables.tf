variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_web_subnet_ids" {
  description = "CIDR blocks of web subnets"
  type        = list(string)
}


variable "private_app_subnet_ids" {
  description = "CIDR blocks of app subnets"
  type        = list(string)
}

variable "private_db_subnet_ids" {
  description = "List of DB subnet IDs"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "web_private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "app_private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}


variable "db_private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the entire VPC"
  type        = string
}