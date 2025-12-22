# ========================================
# COMPUTE - APP TIER MODULE
# ========================================
# Application servers with Blue/Green deployment support
# ========================================

# ===== APP TIER - BLUE ENVIRONMENT =====

# Launch Template for Blue Environment
resource "aws_launch_template" "app_blue" {
  name_prefix   = "${var.project_name}-app-lt-blue-"
  image_id      = var.app_ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.app_sg_id]

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  user_data = base64encode(templatefile("${path.module}/user_data_app_simple.sh.tftpl", {
    db_host      = var.db_host
    db_username  = var.db_username
    db_password  = var.db_password
    db_name      = var.db_name
    project_name = var.project_name
    environment  = "blue"
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-app-instance-blue"
      Environment = "blue"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.project_name}-app-volume-blue"
      Environment = "blue"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for Blue Environment
resource "aws_autoscaling_group" "app_blue" {
  name = "${var.project_name}-app-asg-blue"
  
  launch_template {
    id      = aws_launch_template.app_blue.id
    version = "$Latest"
  }

  min_size             = var.enable_blue_env ? var.min_size : 0
  max_size             = var.max_size
  desired_capacity     = var.enable_blue_env ? var.desired_capacity : 0
  vpc_zone_identifier  = var.private_app_subnet_ids

  health_check_type         = "ELB"
  health_check_grace_period = 600

  target_group_arns = [var.app_target_group_blue_arn]

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
    value               = "${var.project_name}-app-asg-blue"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "blue"
    propagate_at_launch = true
  }
}

# ===== APP TIER - GREEN ENVIRONMENT =====

# Launch Template for Green Environment
resource "aws_launch_template" "app_green" {
  name_prefix   = "${var.project_name}-app-lt-green-"
  image_id      = var.app_ami_id_green != "" ? var.app_ami_id_green : var.app_ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  vpc_security_group_ids = [var.app_sg_id]

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  user_data = base64encode(templatefile("${path.module}/user_data_app_simple.sh.tftpl", {
    db_host      = var.db_host
    db_username  = var.db_username
    db_password  = var.db_password
    db_name      = var.db_name
    project_name = var.project_name
    environment  = "green"
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-app-instance-green"
      Environment = "green"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "${var.project_name}-app-volume-green"
      Environment = "green"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group for Green Environment
resource "aws_autoscaling_group" "app_green" {
  name = "${var.project_name}-app-asg-green"
  
  launch_template {
    id      = aws_launch_template.app_green.id
    version = "$Latest"
  }

  min_size             = var.enable_green_env ? var.min_size : 0
  max_size             = var.max_size
  desired_capacity     = var.enable_green_env ? var.desired_capacity : 0
  vpc_zone_identifier  = var.private_app_subnet_ids

  health_check_type         = "ELB"
  health_check_grace_period = 600

  target_group_arns = [var.app_target_group_green_arn]

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
    value               = "${var.project_name}-app-asg-green"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "green"
    propagate_at_launch = true
  }
}

# ===== AUTO SCALING POLICIES - BLUE ENVIRONMENT =====

resource "aws_autoscaling_policy" "app_blue_scale_up" {
  name                   = "${var.project_name}-app-blue-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.app_blue.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1 
  cooldown               = 300 
}

resource "aws_cloudwatch_metric_alarm" "app_blue_cpu_high" {
  alarm_name          = "${var.project_name}-app-blue-cpu-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 
  statistic           = "Average"
  threshold           = 70 

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_blue.name
  }

  alarm_description = "Kích hoạt scale up khi CPU trung bình của App Blue >= 70%"
  alarm_actions     = [aws_autoscaling_policy.app_blue_scale_up.arn]
}

resource "aws_autoscaling_policy" "app_blue_scale_down" {
  name                   = "${var.project_name}-app-blue-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.app_blue.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "app_blue_cpu_low" {
  alarm_name          = "${var.project_name}-app-blue-cpu-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30 

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_blue.name
  }

  alarm_description = "Kích hoạt scale down khi CPU trung bình của App Blue <= 30%"
  alarm_actions     = [aws_autoscaling_policy.app_blue_scale_down.arn]
}

# ===== AUTO SCALING POLICIES - GREEN ENVIRONMENT =====

resource "aws_autoscaling_policy" "app_green_scale_up" {
  name                   = "${var.project_name}-app-green-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.app_green.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1 
  cooldown               = 300 
}

resource "aws_cloudwatch_metric_alarm" "app_green_cpu_high" {
  alarm_name          = "${var.project_name}-app-green-cpu-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 
  statistic           = "Average"
  threshold           = 70 

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_green.name
  }

  alarm_description = "Kích hoạt scale up khi CPU trung bình của App Green >= 70%"
  alarm_actions     = [aws_autoscaling_policy.app_green_scale_up.arn]
}

resource "aws_autoscaling_policy" "app_green_scale_down" {
  name                   = "${var.project_name}-app-green-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.app_green.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "app_green_cpu_low" {
  alarm_name          = "${var.project_name}-app-green-cpu-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30 

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_green.name
  }

  alarm_description = "Kích hoạt scale down khi CPU trung bình của App Green <= 30%"
  alarm_actions     = [aws_autoscaling_policy.app_green_scale_down.arn]
}
