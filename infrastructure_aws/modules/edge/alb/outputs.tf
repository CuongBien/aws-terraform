# ========================================
# EDGE - ALB MODULE - OUTPUTS
# ========================================

# ===== PUBLIC ALB OUTPUTS =====

output "alb_arn" {
  description = "ARN of the external ALB"
  value       = aws_lb.external.arn
}

output "alb_dns_name" {
  description = "DNS name of the external ALB"
  value       = aws_lb.external.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the external ALB"
  value       = aws_lb.external.zone_id
}

# ===== WEB TARGET GROUPS OUTPUTS =====

output "web_target_group_blue_arn" {
  description = "ARN of Web Blue Target Group"
  value       = aws_lb_target_group.web_blue.arn
}

output "web_target_group_green_arn" {
  description = "ARN of Web Green Target Group"
  value       = aws_lb_target_group.web_green.arn
}

# ===== INTERNAL ALB OUTPUTS =====

output "internal_alb_arn" {
  description = "ARN of the internal ALB"
  value       = aws_lb.internal.arn
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal ALB"
  value       = aws_lb.internal.dns_name
}

output "internal_alb_zone_id" {
  description = "Route53 zone ID of the internal ALB"
  value       = aws_lb.internal.zone_id
}

# ===== APP TARGET GROUPS OUTPUTS =====

output "app_target_group_blue_arn" {
  description = "ARN of App Blue Target Group"
  value       = aws_lb_target_group.app_blue.arn
}

output "app_target_group_green_arn" {
  description = "ARN of App Green Target Group"
  value       = aws_lb_target_group.app_green.arn
}
