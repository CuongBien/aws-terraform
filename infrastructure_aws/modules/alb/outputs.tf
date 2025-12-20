output "alb_arn" {
  value = aws_lb.external.arn
}

output "alb_dns_name" {
  value = aws_lb.external.dns_name
}

output "web_target_group_arn" {
  value = aws_lb_target_group.web.arn
}

output "alb_zone_id" {
  value = aws_lb.external.zone_id
}

output "internal_alb_arn" {
  value = aws_lb.internal.arn
}

output "internal_alb_dns_name" {
  value = aws_lb.internal.dns_name
}

output "app_target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "internal_alb_zone_id" {
  value = aws_lb.internal.zone_id
}
