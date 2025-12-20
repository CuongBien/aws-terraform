# ========================================
# SECURITY MODULE - OUTPUTS
# ========================================

output "alb_sg_id" {
  description = "Public ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "internal_alb_sg_id" {
  description = "Internal ALB Security Group ID"
  value       = aws_security_group.internal_alb.id
}

output "web_sg_id" {
  description = "Web tier Security Group ID"
  value       = aws_security_group.web.id
}

output "app_sg_id" {
  description = "App tier Security Group ID"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Database Security Group ID"
  value       = aws_security_group.db.id
}

output "bastion_sg_id" {
  description = "Bastion Security Group ID"
  value       = aws_security_group.bastion.id
}

# Additional outputs for convenience
output "all_sg_ids" {
  description = "Map of all security group IDs"
  value = {
    alb          = aws_security_group.alb.id
    internal_alb = aws_security_group.internal_alb.id
    web          = aws_security_group.web.id
    app          = aws_security_group.app.id
    db           = aws_security_group.db.id
    bastion      = aws_security_group.bastion.id
  }
}
