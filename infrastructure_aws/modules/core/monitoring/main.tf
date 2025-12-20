# ========================================
# CORE - MONITORING MODULE
# ========================================
# CloudWatch Dashboards, Alarms, SNS Topics
# ========================================

# ===== SNS TOPIC FOR ALARMS =====

resource "aws_sns_topic" "alarms" {
  name              = "${var.project_name}-${var.environment}-alarms-topic"
  kms_master_key_id = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alarms-topic"
    }
  )
}

# ===== SNS EMAIL SUBSCRIPTIONS =====

resource "aws_sns_topic_subscription" "email_subscriptions" {
  count = length(var.alarm_email_endpoints)

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email_endpoints[count.index]
}
