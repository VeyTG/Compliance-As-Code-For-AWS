# EventBridge Configuration
# Schedule Lambda scanner to run periodically

# ===== EventBridge Rule =====
resource "aws_cloudwatch_event_rule" "compliance_scan" {
  name                = "${local.name_prefix}-compliance-scan"
  description         = "Trigger compliance scanner on schedule"
  schedule_expression = var.scan_schedule # rate(1 hour)

  tags = merge(local.common_tags, {
    Name = "Compliance Scan Schedule"
  })
}

# EventBridge Target: Lambda Scanner
resource "aws_cloudwatch_event_target" "scanner" {
  rule      = aws_cloudwatch_event_rule.compliance_scan.name
  target_id = "ComplianceScanner"
  arn       = aws_lambda_function.scanner.arn

  input = jsonencode({
    scan_type = "scheduled"
    controls  = [
      "CIS-AWS-1",
      "CIS-AWS-2",
      "CIS-AWS-3",
      "CIS-AWS-4",
      "CIS-AWS-5",
      "CIS-AWS-6",
      "CIS-AWS-7",
      "CIS-AWS-8",
      "CIS-AWS-9",
      "CIS-AWS-10"
    ]
  })
}

# ===== CloudWatch Alarms =====
# Alarm khi có vi phạm compliance
resource "aws_cloudwatch_metric_alarm" "compliance_violations" {
  alarm_name          = "${local.name_prefix}-compliance-violations"
  alarm_description   = "Alert when compliance violations detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ViolationCount"
  namespace           = "Compliance"
  period              = 3600
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.compliance_alerts.arn]

  tags = local.common_tags
}
