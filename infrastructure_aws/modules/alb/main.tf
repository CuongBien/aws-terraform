# ALB Module Configuration

#tfsec:ignore:aws-elb-alb-not-public # This is the public-facing load balancer
resource "aws_lb" "external" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids  

  enable_deletion_protection = false

  drop_invalid_header_fields = true

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ===== WEB TARGET GROUPS - BLUE/GREEN =====
resource "aws_lb_target_group" "web_blue" {
  name     = "${var.project_name}-web-tg-blue"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
    matcher             = "200-399"
  }

  tags = {
    Name        = "${var.project_name}-web-tg-blue"
    Environment = "blue"
  }
}

resource "aws_lb_target_group" "web_green" {
  name     = "${var.project_name}-web-tg-green"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
    matcher             = "200-399"
  }

  tags = {
    Name        = "${var.project_name}-web-tg-green"
    Environment = "green"
  }
}

# ===== LISTENER WITH WEIGHTED TARGET GROUPS =====
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    
    forward {
      target_group {
        arn    = aws_lb_target_group.web_blue.arn
        weight = var.traffic_distribution_blue
      }

      target_group {
        arn    = aws_lb_target_group.web_green.arn
        weight = var.traffic_distribution_green
      }

      stickiness {
        enabled  = false
        duration = 3600
      }
    }
  }
}

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.external.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web.arn
#   }
# }

# Internal ALB for web-app communication
resource "aws_lb" "internal" {
  name               = "${var.project_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.private_web_subnet_ids

  enable_deletion_protection = false

  drop_invalid_header_fields = true

  tags = {
    Name = "${var.project_name}-internal-alb"
  }
}

# ===== APP TARGET GROUPS - BLUE/GREEN =====
resource "aws_lb_target_group" "app_blue" {
  name     = "${var.project_name}-app-blue-v3" 
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
    matcher             = "200-399"
  }

  tags = {
    Name        = "${var.project_name}-app-tg-blue"
    Environment = "blue"
  }
}

resource "aws_lb_target_group" "app_green" {
  name     = "${var.project_name}-app-green-v3" 
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    healthy_threshold   = 2
    matcher             = "200-399"
  }

  tags = {
    Name        = "${var.project_name}-app-tg-green"
    Environment = "green"
  }
}

# ===== INTERNAL LISTENER WITH WEIGHTED TARGET GROUPS =====
#tfsec:ignore:aws-elb-http-not-used # Internal traffic is considered trusted
resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    
    forward {
      target_group {
        arn    = aws_lb_target_group.app_blue.arn
        weight = var.traffic_distribution_blue
      }

      target_group {
        arn    = aws_lb_target_group.app_green.arn
        weight = var.traffic_distribution_green
      }

      stickiness {
        enabled  = true
        duration = 3600
      }
    }
  }
}

# --- CloudWatch Alarm for ALB 5xx Errors ---
resource "aws_cloudwatch_metric_alarm" "public_alb_5xx_errors" {
  alarm_name          = "${var.project_name}-public-alb-high-5xx-errors-alarm"
  
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  
  metric_name         = "HTTPCode_Target_5XX_Count" 
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum" 
  threshold           = 5    

  dimensions = {
    LoadBalancer = aws_lb.external.arn_suffix
  }

  alarm_description = "Kích hoạt khi Public ALB có quá nhiều lỗi 5xx từ server"
  alarm_actions     = [var.sns_topic_arn]
  ok_actions        = [var.sns_topic_arn]
}
