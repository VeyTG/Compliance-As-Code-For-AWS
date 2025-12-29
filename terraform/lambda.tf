# Lambda Functions Configuration

# ===== Lambda Scanner Function =====
resource "aws_lambda_function" "scanner" {
  filename      = "${path.module}/../lambda/scanner.zip"
  function_name = "${local.name_prefix}-scanner"
  role          = aws_iam_role.lambda_scanner.arn
  handler       = "scanner.lambda_handler"
  runtime       = "python3.10"
  timeout       = 300 # 5 minutes
  memory_size   = 512

  source_code_hash = fileexists("${path.module}/../lambda/scanner.zip") ? filebase64sha256("${path.module}/../lambda/scanner.zip") : ""

  environment {
    variables = {
      EVIDENCE_BUCKET      = aws_s3_bucket.evidence.id
      REMEDIATION_FUNCTION = aws_lambda_function.remediation.function_name
      SNS_TOPIC_ARN        = aws_sns_topic.compliance_alerts.arn
      ENVIRONMENT          = var.environment
    }
  }

  tags = merge(local.common_tags, {
    Name        = "Compliance Scanner"
    Description = "Scan AWS resources for CIS compliance violations"
  })

  depends_on = [
    aws_iam_role_policy.lambda_scanner
  ]
}

# CloudWatch Log Group cho Scanner
resource "aws_cloudwatch_log_group" "scanner" {
  name              = "/aws/lambda/${aws_lambda_function.scanner.function_name}"
  retention_in_days = 7

  tags = local.common_tags
}

# ===== Lambda Remediation Function =====
resource "aws_lambda_function" "remediation" {
  filename      = "${path.module}/../lambda/remediation.zip"
  function_name = "${local.name_prefix}-remediation"
  role          = aws_iam_role.lambda_remediation.arn
  handler       = "remediation.lambda_handler"
  runtime       = "python3.10"
  timeout       = 300 # 5 minutes
  memory_size   = 512

  source_code_hash = fileexists("${path.module}/../lambda/remediation.zip") ? filebase64sha256("${path.module}/../lambda/remediation.zip") : ""

  environment {
    variables = {
      EVIDENCE_BUCKET = aws_s3_bucket.evidence.id
      SNS_TOPIC_ARN   = aws_sns_topic.compliance_alerts.arn
      ENVIRONMENT     = var.environment
    }
  }

  tags = merge(local.common_tags, {
    Name        = "Compliance Remediation"
    Description = "Auto-fix compliance violations"
  })

  depends_on = [
    aws_iam_role_policy.lambda_remediation
  ]
}

# CloudWatch Log Group cho Remediation
resource "aws_cloudwatch_log_group" "remediation" {
  name              = "/aws/lambda/${aws_lambda_function.remediation.function_name}"
  retention_in_days = 7

  tags = local.common_tags
}

# ===== Lambda Permissions =====
# Cho phép EventBridge invoke Scanner
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scanner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.compliance_scan.arn
}
