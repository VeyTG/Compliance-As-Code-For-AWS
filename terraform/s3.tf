# S3 Buckets Configuration - Fully Compliant for CIS-AWS-3/4/5/6

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

# ===== LOG BUCKET (for access logging) =====
resource "aws_s3_bucket" "log_bucket" {
  bucket = "evidence-log-bucket-${random_id.suffix.hex}"

  acl = "log-delivery-write"

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

  tags = merge(local.common_tags, {
    Name        = "S3 Access Log Bucket"
    Compliance  = "CIS-AWS-5"
    Description = "Bucket để lưu access logs"
  })
}

# ===== COMPLIANT BUCKET: Evidence Storage =====
resource "aws_s3_bucket" "evidence" {
  bucket = "${var.evidence_bucket_name}-${random_id.suffix.hex}"

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

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "evidence-logs/"
  }

  tags = merge(local.common_tags, {
    Name        = "Compliance Evidence Bucket"
    Compliance  = "CIS-AWS-3,CIS-AWS-5,CIS-AWS-6"
    Description = "Lưu trữ scan results và evidence"
  })
}

# Public access block (CIS-AWS-5)
resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===== REPLICATION (CIS-AWS-3) =====
# IAM Role for replication
resource "aws_iam_role" "replication_role" {
  name = "s3-replication-role"

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
resource "aws_s3_bucket" "evidence_replica" {
  bucket = "evidence-replica-bucket-${random_id.suffix.hex}"

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

  tags = merge(local.common_tags, {
    Name        = "Evidence Replica Bucket"
    Compliance  = "CIS-AWS-3"
    Description = "Replica bucket for cross-region replication"
  })
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  role   = aws_iam_role.replication_role.arn

  rules {
    id     = "replication-rule"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.evidence_replica.arn
      storage_class = "STANDARD"
    }

    filter {}
  }
}

# ===== COMPLIANT BUCKET: CloudTrail Logs =====
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "${var.cloudtrail_bucket_name}-${random_id.suffix.hex}"

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

  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "cloudtrail-logs/"
  }

  tags = merge(local.common_tags, {
    Name        = "CloudTrail Logs Bucket"
    Compliance  = "CIS-AWS-3,CIS-AWS-5,CIS-AWS-6"
    Description = "Lưu trữ CloudTrail logs"
  })
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
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

# ===== NON-COMPLIANT BUCKET: Test Purpose (for demo) =====
resource "aws_s3_bucket" "test_non_compliant" {
  bucket = "test-non-compliant-${random_id.suffix.hex}"

  tags = merge(local.common_tags, {
    Name        = "Non-Compliant Test Bucket"
    Compliance  = "VIOLATION"
    Description = "Bucket để test scanner và remediation"
  })
}

resource "aws_s3_bucket_public_access_block" "test_non_compliant" {
  bucket = aws_s3_bucket.test_non_compliant.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Không tạo encryption + versioning → non-compliant

