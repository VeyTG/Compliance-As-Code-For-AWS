package aws.compliance

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_cloudtrail"
  resource.change.after.is_multi_region_trail == false

  msg := {
    "control": "CIS-AWS-3",
    "severity": "HIGH",
    "resource": resource.address,
    "message": "CloudTrail is not multi-region"
  }
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_cloudtrail"
  resource.change.after.enable_log_file_validation == false

  msg := {
    "control": "CIS-AWS-4",
    "severity": "HIGH",
    "resource": resource.address,
    "message": "CloudTrail log validation disabled"
  }
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_public_access_block"
  resource.change.after.block_public_acls == false

  msg := {
    "control": "CIS-AWS-5",
    "severity": "CRITICAL",
    "resource": resource.address,
    "message": "S3 bucket allows public ACLs"
  }
}

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket_server_side_encryption_configuration"

  rule := resource.change.after.rule[_]
  rule.apply_server_side_encryption_by_default.sse_algorithm == ""

  msg := {
    "control": "CIS-AWS-6",
    "severity": "HIGH",
    "resource": resource.address,
    "message": "S3 bucket encryption not enabled"
  }
}

