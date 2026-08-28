# ---------------------------------------------
# Private Subnets
# ---------------------------------------------
resource "aws_subnet" "private" {
  count = length(var.private_subnets.cidr_blocks)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets.cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.tags, var.private_subnets.tags,
    {
      Name             = "${local.vpc_name}-private-subnet-${count.index}"
      Type             = "Private Subnet"
      Access           = "Private"
      Tier             = "Private"
      AvailabilityZone = var.availability_zones[count.index]
    }
  )
}


# ---------------------------------------------
# Public Subnets
# ---------------------------------------------
resource "aws_subnet" "public" {
  count = length(var.public_subnets.cidr_blocks)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnets.cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = merge(local.tags, var.public_subnets.tags,
    {
      Name             = "${local.vpc_name}-public-subnet-${count.index}"
      Type             = "Public Subnet"
      Access           = "Public"
      Tier             = "Public"
      AvailabilityZone = var.availability_zones[count.index]
  })
}


# ---------------------------------------------
# Isolated Subnets
# ---------------------------------------------
resource "aws_subnet" "isolated" {
  count = var.isolated_subnets != null ? length(var.isolated_subnets.cidr_blocks) : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.isolated_subnets.cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.tags, var.isolated_subnets.tags,
    {
      Name             = "${local.vpc_name}-isolated-subnet-${count.index}"
      Type             = "Isolated Subnet"
      Access           = "Isolated"
      Tier             = "Isolated"
      AvailabilityZone = var.availability_zones[count.index]
    }
  )
}

