# Security Groups Configuration
# Bao gồm compliant và non-compliant examples

# ===== COMPLIANT SECURITY GROUP =====
resource "aws_security_group" "compliant" {
  name        = "${local.name_prefix}-compliant-sg"
  description = "Compliant security group - SSH only from internal network"
  vpc_id      = aws_vpc.main.id

  # ✅ COMPLIANT: SSH chỉ từ internal CIDR
  ingress {
    description = "SSH from internal network only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # 10.0.0.0/8
  }

  # ✅ COMPLIANT: HTTPS từ internal
  ingress {
    description = "HTTPS from internal"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name       = "Compliant Security Group"
    Compliance = "CIS-AWS-7,CIS-AWS-8"
  })
}

# ===== NON-COMPLIANT SECURITY GROUP: Test Purpose =====
resource "aws_security_group" "non_compliant" {
  name        = "${local.name_prefix}-non-compliant-sg"
  description = "NON-COMPLIANT security group for testing - DO NOT USE IN PRODUCTION"
  vpc_id      = aws_vpc.main.id

  # ❌ VIOLATION CIS-AWS-7: SSH from internet
  ingress {
    description = "SSH from anywhere - VIOLATION!"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ❌ Vi phạm!
  }

  # ❌ VIOLATION CIS-AWS-8: RDP from internet
  ingress {
    description = "RDP from anywhere - VIOLATION!"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ❌ Vi phạm!
  }

  # Telnet (thêm violation khác để demo)
  ingress {
    description = "Telnet from anywhere - VIOLATION!"
    from_port   = 23
    to_port     = 23
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name       = "Non-Compliant Security Group"
    Compliance = "VIOLATION"
    Purpose    = "Testing scanner and remediation"
  })
}

# ===== CIS-AWS-9: Default Security Group =====
# Ensure default security group restricts all traffic
# Terraform không tạo default SG, nhưng ta có thể manage nó

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # ✅ COMPLIANT: No ingress rules
  # ✅ COMPLIANT: No egress rules
  # Empty = restrict all traffic

  tags = merge(local.common_tags, {
    Name       = "Default SG - Restricted"
    Compliance = "CIS-AWS-9"
  })
}
