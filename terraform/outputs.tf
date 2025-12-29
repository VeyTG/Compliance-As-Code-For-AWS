# Terraform Outputs

output "evidence_bucket_name" {
  description = "Tên S3 bucket chứa compliance evidence"
  value       = aws_s3_bucket.evidence.id
}

output "cloudtrail_bucket_name" {
  description = "Tên S3 bucket chứa CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "scanner_lambda_arn" {
  description = "ARN của Lambda scanner function"
  value       = aws_lambda_function.scanner.arn
}

output "remediation_lambda_arn" {
  description = "ARN của Lambda remediation function"
  value       = aws_lambda_function.remediation.arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "compliant_sg_id" {
  description = "Security Group ID (compliant)"
  value       = aws_security_group.compliant.id
}

output "non_compliant_sg_id" {
  description = "Security Group ID (non-compliant - for testing)"
  value       = aws_security_group.non_compliant.id
}

output "sns_topic_arn" {
  description = "SNS Topic ARN cho alerts"
  value       = aws_sns_topic.compliance_alerts.arn
}

output "eventbridge_rule_name" {
  description = "EventBridge rule name"
  value       = aws_cloudwatch_event_rule.compliance_scan.name
}
