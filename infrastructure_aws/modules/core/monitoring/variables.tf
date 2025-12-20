# ========================================
# CORE - MONITORING MODULE - VARIABLES
# ========================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alarm_email_endpoints" {
  description = "List of email addresses for alarm notifications"
  type        = list(string)
}

variable "kms_key_id" {
  description = "KMS key ID for SNS encryption"
  type        = string
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}
