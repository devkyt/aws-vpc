# =============================================
# VPC
# =============================================

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


# ---------------------------------------------
# S3 Gateway VPC Endpoint
# ---------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"

  service_name = "com.amazonaws.${data.aws_region.current.region}.s3"

  route_table_ids = local.route_table_ids_for_gateway_endpoints

  policy = var.s3_gateway_policy

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-s3-gateway"
      Type = "VPC Endpoint"
    }
  )

  lifecycle {
    enabled = var.create_s3_gateway
  }
}


# ---------------------------------------------
# DynamoDB Gateway VPC Endpoint
# ---------------------------------------------
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"

  service_name = "com.amazonaws.${data.aws_region.current.region}.dynamodb"

  route_table_ids = local.route_table_ids_for_gateway_endpoints

  policy = var.dynamodb_gateway_policy

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-dynamodb-gateway"
      Type = "VPC Endpoint"
    }
  )

  lifecycle {
    enabled = var.create_dynamodb_gateway
  }
}


# =============================================
# Public Resources
# =============================================

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


# =============================================
# Private Resources
# =============================================

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


# =============================================
# Isolated Resources
# =============================================

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


# ---------------------------------------------
# Isolated Route Table
# ---------------------------------------------
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.main.id

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


# =============================================
# Logs
# =============================================

# ---------------------------------------------
# VPC Flow Log
# ---------------------------------------------
resource "aws_flow_log" "main" {
  vpc_id       = aws_vpc.main.id
  traffic_type = var.flow_log.traffic_type

  log_destination_type = var.flow_log.log_destination_type
  log_destination      = local.flow_log_destination_arn
  log_format           = var.flow_log.log_format

  iam_role_arn               = local.flow_log_iam_role_arn
  deliver_cross_account_role = var.flow_log.cross_account_role_arn

  max_aggregation_interval = var.flow_log.aggregation_interval_sec

  dynamic "destination_options" {
    for_each = var.flow_log.log_destination_type == "s3" ? ["enable"] : []

    content {
      file_format                = var.flow_log.destination_options.file_format
      hive_compatible_partitions = var.flow_log.destination_options.hive_compatible_partitions
      per_hour_partition         = var.flow_log.destination_options.per_hour_partition
    }
  }

  tags = merge(local.tags,
    {
      Name = "${local.vpc_name}-flow-log"
      Type = "VPC Flow Log"
    }
  )

  lifecycle {
    enabled = var.flow_log.enable
  }
}


# ---------------------------------------------
# CloudWatch Log Group For Flow Logs
# ---------------------------------------------
resource "aws_cloudwatch_log_group" "main" {
  name = local.cloudwatch_log_group_name

  kms_key_id        = var.cloudwatch_log_group.kms_key_id
  retention_in_days = var.cloudwatch_log_group.retention_days
  log_group_class   = var.cloudwatch_log_group.log_group_class

  skip_destroy = var.cloudwatch_log_group.skip_destroy

  tags = merge(local.tags,
    {
      Name = local.cloudwatch_log_group_name
      Type = "CloudWatch Log Group"
    }
  )

  lifecycle {
    enabled = local.create_cloudwatch
  }
}
