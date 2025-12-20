# ========================================
# COMPUTE - WEB TIER MODULE - OUTPUTS
# ========================================

output "web_asg_blue_name" {
  description = "Name of the web blue ASG"
  value       = aws_autoscaling_group.web_blue.name
}

output "web_asg_green_name" {
  description = "Name of the web green ASG"
  value       = aws_autoscaling_group.web_green.name
}

output "web_asg_blue_arn" {
  description = "ARN of the web blue ASG"
  value       = aws_autoscaling_group.web_blue.arn
}

output "web_asg_green_arn" {
  description = "ARN of the web green ASG"
  value       = aws_autoscaling_group.web_green.arn
}

output "web_lt_blue_id" {
  description = "ID of the web blue launch template"
  value       = aws_launch_template.web_blue.id
}

output "web_lt_green_id" {
  description = "ID of the web green launch template"
  value       = aws_launch_template.web_green.id
}
