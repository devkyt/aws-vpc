# ---------------------------------------------
# Internet Gateway
# ---------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-internet-gateway"
      Type = "Internet Gateway"
    }
  )
}

# ---------------------------------------------
# Elastic IPs For NAT Gateways
# ---------------------------------------------
resource "aws_eip" "nat" {
  count = var.high_availability_nat ? length(var.availability_zones) : 1

  domain = "vpc"

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-nat-eip"
      AZ   = var.high_availability_nat ? var.availability_zones[count.index] : "common"
      Type = "EIP"
    }
  )
}


# ---------------------------------------------
# NAT Gateways
# ---------------------------------------------
resource "aws_nat_gateway" "main" {
  count = var.high_availability_nat ? length(var.availability_zones) : 1

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-nat-gateway"
      AZ   = var.high_availability_nat ? var.availability_zones[count.index] : "common"
      Type = "NAT Gateway"
    }
  )

  depends_on = [aws_internet_gateway.main]
}
