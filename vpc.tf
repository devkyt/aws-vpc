# ---------------------------------------------
# Main VPC
# ---------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags,
    {
      Name = local.vpc_name
      Type = "VPC"
    }
  )
}


# ---------------------------------------------
# Default Security Group Lockdown
# ---------------------------------------------
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-default-sg"
      Type = "Default Security Group"
    }
  )
}
