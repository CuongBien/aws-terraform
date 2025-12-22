# ========================================
# DATA - RDS MODULE - OUTPUTS
# ========================================

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = data.aws_db_instance.main.id
}

output "db_endpoint" {
  description = "The connection endpoint (hostname)"
  value       = data.aws_db_instance.main.address
}

output "db_port" {
  description = "The database port"
  value       = data.aws_db_instance.main.port
}

output "db_name" {
  description = "The database name"
  value       = data.aws_db_instance.main.db_name
}

output "db_username" {
  description = "The master username"
  value       = data.aws_db_instance.main.master_username
  sensitive   = true
}

output "db_arn" {
  description = "The ARN of the RDS instance"
  value       = data.aws_db_instance.main.db_instance_arn
}

output "db_subnet_group_name" {
  description = "The DB subnet group name"
  value       = aws_db_subnet_group.main.name
}
