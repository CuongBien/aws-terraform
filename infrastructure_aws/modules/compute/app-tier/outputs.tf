# ========================================
# COMPUTE - APP TIER MODULE - OUTPUTS
# ========================================

output "app_asg_blue_name" {
  description = "Name of the app blue ASG"
  value       = aws_autoscaling_group.app_blue.name
}

output "app_asg_green_name" {
  description = "Name of the app green ASG"
  value       = aws_autoscaling_group.app_green.name
}

output "app_asg_blue_arn" {
  description = "ARN of the app blue ASG"
  value       = aws_autoscaling_group.app_blue.arn
}

output "app_asg_green_arn" {
  description = "ARN of the app green ASG"
  value       = aws_autoscaling_group.app_green.arn
}

output "app_lt_blue_id" {
  description = "ID of the app blue launch template"
  value       = aws_launch_template.app_blue.id
}

output "app_lt_green_id" {
  description = "ID of the app green launch template"
  value       = aws_launch_template.app_green.id
}
