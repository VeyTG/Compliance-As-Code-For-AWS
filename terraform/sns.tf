# SNS Topic cho Compliance Alerts

# ===== SNS Topic =====
resource "aws_sns_topic" "compliance_alerts" {
  name         = "${local.name_prefix}-compliance-alerts"
  display_name = "AWS Compliance Alerts"

  tags = merge(local.common_tags, {
    Name = "Compliance Alerts Topic"
  })
}

# SNS Subscription (Email)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.compliance_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "compliance_alerts" {
  arn = aws_sns_topic.compliance_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "cloudwatch.amazonaws.com"
          ]
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.compliance_alerts.arn
      }
    ]
  })
}
