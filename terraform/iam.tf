# IAM Roles và Policies cho Lambda Functions

# ===== Lambda Scanner Role =====
resource "aws_iam_role" "lambda_scanner" {
  name = "${local.name_prefix}-lambda-scanner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "Lambda Scanner Role"
  })
}

# Policy cho Lambda Scanner
resource "aws_iam_role_policy" "lambda_scanner" {
  name = "${local.name_prefix}-lambda-scanner-policy"
  role = aws_iam_role.lambda_scanner.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # S3 Read/Write cho evidence bucket
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetEncryptionConfiguration"
        ]
        Resource = [
          aws_s3_bucket.evidence.arn,
          "${aws_s3_bucket.evidence.arn}/*",
          "arn:aws:s3:::*" # Scan all buckets
        ]
      },
      # EC2 Read (Security Groups, VPC)
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeFlowLogs",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      # IAM Read (Root account checks)
      {
        Effect = "Allow"
        Action = [
          "iam:GetAccountSummary",
          "iam:ListAccessKeys",
          "iam:ListMFADevices",
          "iam:GetAccountPasswordPolicy"
        ]
        Resource = "*"
      },
      # CloudTrail Read
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetTrailStatus",
          "cloudtrail:GetEventSelectors"
        ]
        Resource = "*"
      },
      # Invoke remediation Lambda
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.remediation.arn
      },
      # SNS Publish
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.compliance_alerts.arn
      }
    ]
  })
}

# ===== Lambda Remediation Role =====
resource "aws_iam_role" "lambda_remediation" {
  name = "${local.name_prefix}-lambda-remediation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "Lambda Remediation Role"
  })
}

# Policy cho Lambda Remediation
resource "aws_iam_role_policy" "lambda_remediation" {
  name = "${local.name_prefix}-lambda-remediation-policy"
  role = aws_iam_role.lambda_remediation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # S3 Remediation
      {
        Effect = "Allow"
        Action = [
          "s3:PutPublicAccessBlock",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::*",
          aws_s3_bucket.evidence.arn,
          "${aws_s3_bucket.evidence.arn}/*"
        ]
      },
      # EC2 Remediation (Security Groups)
      {
        Effect = "Allow"
        Action = [
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateFlowLogs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      },
      # CloudTrail Remediation
      {
        Effect = "Allow"
        Action = [
          "cloudtrail:UpdateTrail",
          "cloudtrail:StartLogging"
        ]
        Resource = "*"
      },
      # SNS Publish
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.compliance_alerts.arn
      }
    ]
  })
}
