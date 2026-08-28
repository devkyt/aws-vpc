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
