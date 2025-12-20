# ASG Module Configuration for Web Tier

resource "aws_launch_template" "web" {
  name          = "${var.project_name}-web-lt"
  image_id      = var.web_ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.web_sg_id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Bắt buộc phải có token (IMDSv2)
    http_put_response_hop_limit = 1
  }

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  user_data = base64encode(templatefile("${path.module}/user_data_web.sh.tftpl", {
  internal_alb_dns_name = var.internal_alb_dns_name
  project_name          = var.project_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-web-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-web-volume"
    }
  }

  lifecycle { 
    create_before_destroy = true # Tạo resource trước khi xóa resource cũ 
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity # Số lượng instance khi khoi tạo
  vpc_zone_identifier  = var.private_web_subnet_ids # Các subnet để triển khai ASG

  health_check_type         = "ELB"
  health_check_grace_period = 600

  target_group_arns = [var.web_target_group_arn]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }
}

# Similarly, for App Tier ASG

resource "aws_launch_template" "app" {
  name          = "${var.project_name}-app-lt"
  image_id      = var.app_ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.app_sg_id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Bắt buộc phải có token (IMDSv2)
    http_put_response_hop_limit = 1
  }

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  user_data = base64encode(templatefile("${path.module}/user_data_app.sh.tftpl", {
      db_host      = var.db_host
      db_username  = var.db_username
      db_password  = var.db_password
      db_name      = var.db_name
      project_name = var.project_name
      shop_url     = "http://${var.alb_dns_name}/" # URL của shop
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-app-volume"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-app-asg"
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = var.private_app_subnet_ids

  health_check_type         = "ELB"
  health_check_grace_period = 600

  target_group_arns = [var.app_target_group_arn]

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-asg"
    propagate_at_launch = true
  }
}

# POLICY 1: SCALE UP (Thêm 1 instance)
resource "aws_autoscaling_policy" "web_scale_up" {
  name                   = "${var.project_name}-web-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1 
  cooldown               = 300 
}

# ALARM 1: Kích hoạt SCALE UP khi CPU cao
resource "aws_cloudwatch_metric_alarm" "web_cpu_high" {
  alarm_name          = "${var.project_name}-web-cpu-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 
  statistic           = "Average"
  threshold           = 70 

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Kích hoạt scale up khi CPU trung bình của Web Tier >= 70%"
  alarm_actions     = [aws_autoscaling_policy.web_scale_up.arn]
}

# POLICY 2: SCALE DOWN (Bớt 1 instance)
resource "aws_autoscaling_policy" "web_scale_down" {
  name                   = "${var.project_name}-web-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  
  cooldown               = 300
}

# ALARM 2: Kích hoạt SCALE DOWN khi CPU thấp
resource "aws_cloudwatch_metric_alarm" "web_cpu_low" {
  alarm_name          = "${var.project_name}-web-cpu-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30 

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Kích hoạt scale down khi CPU trung bình của Web Tier <= 30%"
  alarm_actions     = [aws_autoscaling_policy.web_scale_down.arn]
}

# POLICY 1: SCALE UP (Thêm 1 instance)
resource "aws_autoscaling_policy" "app_scale_up" {
  name                   = "${var.project_name}-app-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1 
  cooldown               = 300 
}

# ALARM 1: Kích hoạt SCALE UP khi CPU cao
resource "aws_cloudwatch_metric_alarm" "app_cpu_high" {
  alarm_name          = "${var.project_name}-app-cpu-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 
  statistic           = "Average"
  threshold           = 70 

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_description = "Kích hoạt scale up khi CPU trung bình của App Tier >= 70%"
  alarm_actions     = [aws_autoscaling_policy.app_scale_up.arn]
}

# POLICY 2: SCALE DOWN (Bớt 1 instance)
resource "aws_autoscaling_policy" "app_scale_down" {
  name                   = "${var.project_name}-app-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  
  cooldown               = 300
}

# ALARM 2: Kích hoạt SCALE DOWN khi CPU thấp
resource "aws_cloudwatch_metric_alarm" "app_cpu_low" {
  alarm_name          = "${var.project_name}-app-cpu-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30 

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_description = "Kích hoạt scale down khi CPU trung bình của App Tier <= 30%"
  alarm_actions     = [aws_autoscaling_policy.app_scale_down.arn]
}