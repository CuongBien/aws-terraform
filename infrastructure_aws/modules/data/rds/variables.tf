# ========================================
# DATA - RDS MODULE - VARIABLES
# ========================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "List of private DB subnet IDs"
  type        = list(string)

  validation {
    condition     = length(var.private_db_subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for RDS subnet group."
  }
}

variable "db_sg_id" {
  description = "DB security group ID"
  type        = string
}

# ===== DATABASE CONFIGURATION =====

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
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

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "Allocated storage must be between 20 and 1000 GB."
  }
}

variable "db_username" {
  description = "DB master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "DB master password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "opencart_db"
}

# ===== HIGH AVAILABILITY =====

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

# ===== BACKUP CONFIGURATION =====

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# ===== DELETION PROTECTION =====

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting (set to false for production)"
  type        = bool
  default     = true
}
