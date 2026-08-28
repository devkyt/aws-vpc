# ---------------------------------------------
# Private Route Table And NAT Routes
# ---------------------------------------------
resource "aws_route_table" "private" {
  count = var.high_availability_nat ? length(var.availability_zones) : 1

  vpc_id = aws_vpc.main.id

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-private-route-table"
      AZ   = var.high_availability_nat ? var.availability_zones[count.index] : "common"
      Type = "Private Route Table"
    }
  )
}


resource "aws_route" "private_nat" {
  count = var.high_availability_nat ? length(var.availability_zones) : 1

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id
}


resource "aws_route_table_association" "private" {
  count = length(var.private_subnets.cidr_blocks)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.high_availability_nat ? count.index : 0].id
}


# ---------------------------------------------
# Public Route Table And Internet Route
# ---------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-public-route-table"
      Type = "Public Route Table"
    }
  )
}


resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}


resource "aws_route_table_association" "public" {
  count = length(var.public_subnets.cidr_blocks)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# ---------------------------------------------
# Isolated Route Table
# ---------------------------------------------
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id

  # No routes defined - truly isolated (only implicit local VPC route)

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-isolated-route-table"
      Type = "Isolated Route Table"
    }
  )

  lifecycle {
    enabled = var.isolated_subnets != null
  }
}


resource "aws_route_table_association" "isolated" {
  count = var.isolated_subnets != null ? length(var.isolated_subnets.cidr_blocks) : 0

  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}

