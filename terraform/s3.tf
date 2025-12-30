# S3 Buckets Configuration
# Bao gồm cả compliant và non-compliant examples để demo

# ===== RANDOM SUFFIX =====
resource "random_id" "suffix" {
  byte_length = 4
}

# ===== COMMON TAGS =====
locals {
  common_tags = {
    Project     = "Compliance-Demo"
    Environment = "Dev"
  }
}

# ===== COMPLIANT BUCKET: Evidence Storage =====
resource "aws_s3_bucket" "evidence" {
  bucket = "${var.evidence_bucket_name}-${random_id.suffix.hex}"

  tags = merge(local.common_tags, {
    Name        = "Compliance Evidence Bucket"
    Compliance  = "CIS-AWS-5,CIS-AWS-6"
    Description = "Lưu trữ scan results và evidence"
  })
}

# CIS-AWS-5: Block public access
resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CIS-AWS-6: Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ===== COMPLIANT BUCKET: CloudTrail Logs =====
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.cloudtrail_bucket_name}-${random_id.suffix.hex}"

  tags = merge(local.common_tags, {
    Name        = "CloudTrail Logs Bucket"
    Compliance  = "CIS-AWS-3,CIS-AWS-4"
    Description = "Lưu trữ CloudTrail logs"
  })
}

# CIS-AWS-5: Block public access
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CIS-AWS-6: Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

# CIS-AWS-3: Cross-region replication
# IAM Role for replication
resource "aws_iam_role" "cloudtrail_replication_role" {
  name = "cloudtrail-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# Replica bucket (another region)
resource "aws_s3_bucket" "cloudtrail_replica" {
  bucket = "cloudtrail-replica-${random_id.suffix.hex}"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  role   = aws_iam_role.cloudtrail_replication_role.arn

  rules {
    id     = "replication-rule"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.cloudtrail_replica.arn
      storage_class = "STANDARD"
    }

    filter {}
  }
}

# CloudTrail bucket policy
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      }
    ]
  })
}

# ===== NON-COMPLIANT BUCKET: Test Purpose =====
# Bucket này để demo violations và auto-remediation
resource "aws_s3_bucket" "test_non_compliant" {
  bucket = "test-non-compliant-${random_id.suffix.hex}"

  tags = merge(local.common_tags, {
    Name        = "Non-Compliant Test Bucket"
    Compliance  = "VIOLATION"
    Description = "Bucket để test scanner và remediation"
  })
}

# ❌ VIOLATION CIS-AWS-5: Public access allowed
resource "aws_s3_bucket_public_access_block" "test_non_compliant" {
  bucket = aws_s3_bucket.test_non_compliant.id

  block_public_acls       = false # ❌ Vi phạm!
  block_public_policy     = false # ❌ Vi phạm!
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ❌ VIOLATION CIS-AWS-6: No encryption
# (Không tạo encryption config = không có encryption)
