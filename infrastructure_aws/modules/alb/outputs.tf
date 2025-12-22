output "alb_arn" {
  value = aws_lb.external.arn
}

output "alb_dns_name" {
  value = aws_lb.external.dns_name
}

output "alb_zone_id" {
  value = aws_lb.external.zone_id
}

# ===== BLUE TARGET GROUPS =====
output "web_target_group_blue_arn" {
  value       = aws_lb_target_group.web_blue.arn
  description = "ARN of Web Blue Target Group"
}

output "app_target_group_blue_arn" {
  value       = aws_lb_target_group.app_tg["blue-v3"].arn
  description = "ARN of App Blue Target Group"
}

# ===== GREEN TARGET GROUPS =====
output "web_target_group_green_arn" {
  value       = aws_lb_target_group.web_green.arn
  description = "ARN of Web Green Target Group"
}

output "app_target_group_green_arn" {
  value       = aws_lb_target_group.app_tg["green-v3"].arn
  description = "ARN of App Green Target Group"
}

# ===== INTERNAL ALB =====
output "internal_alb_arn" {
  value = aws_lb.internal.arn
}

output "internal_alb_dns_name" {
  value = aws_lb.internal.dns_name
}

output "internal_alb_zone_id" {
  value = aws_lb.internal.zone_id
}
