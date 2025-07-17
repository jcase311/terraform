
resource "aws_sns_topic" "route53_notifications" {
  name = "route53-change-alerts"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.route53_notifications.arn
  protocol  = "email"
  endpoint  = "jcase311@gmail.com"
}

resource "aws_cloudwatch_event_rule" "route53_changes" {
  name        = "route53-change-events"
  description = "Capture Route 53 change events"
  event_pattern = jsonencode({
    source = ["aws.route53"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["route53.amazonaws.com"]
      eventName   = [
        "ChangeResourceRecordSets",
        "CreateHostedZone",
        "DeleteHostedZone",
        "UpdateHostedZoneComment"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.route53_changes.name
  target_id = "sendRoute53ChangesToSNS"
  arn       = aws_sns_topic.route53_notifications.arn
}

resource "aws_cloudwatch_log_group" "eventbridge_logs" {
  name              = "/aws/events/route53"
  retention_in_days = 30
}
