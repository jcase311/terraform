provider "aws" {
  region = "us-east-2"
}

# SNS topic for alerting
resource "aws_sns_topic" "ta_alerts" {
  name = "trusted-advisor-critical-alerts"
}

# Email subscription to SNS topic
resource "aws_sns_topic_subscription" "ta_email" {
  topic_arn = aws_sns_topic.ta_alerts.arn
  protocol  = "email"
  endpoint  = "jcase311+trustedadvisor@gmail.com"
}

# EventBridge rule for Trusted Advisor critical alerts
resource "aws_cloudwatch_event_rule" "ta_critical_alerts" {
  name        = "TrustedAdvisorCriticalAlerts"
  description = "Catch Trusted Advisor critical-level checks"
  event_pattern = jsonencode({
    "source": ["aws.trustedadvisor"],
    "detail-type": ["Trusted Advisor Check Item Refresh Notification"],
    "detail": {
      "status": ["error", "warning"],  # TA uses these for actionable items
      "check-name": [{"exists": true}]
    }
  })
}

# Send matched events to SNS topic
resource "aws_cloudwatch_event_target" "ta_alert_target" {
  rule      = aws_cloudwatch_event_rule.ta_critical_alerts.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.ta_alerts.arn
}

# Give EventBridge permission to publish to SNS
resource "aws_sns_topic_policy" "ta_topic_policy" {
  arn = aws_sns_topic.ta_alerts.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = "sns:Publish",
        Resource = aws_sns_topic.ta_alerts.arn
      }
    ]
  })
}
