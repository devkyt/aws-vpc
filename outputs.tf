output "vpc_id" {
  description = "The ID of created VPC"
  value       = aws_vpc.main.id
}


output "vpc_cidr" {
  description = "The CIDR block of created VPC"
  value       = aws_vpc.main.cidr_block
}


output "private_subnet_ids" {
  description = "The IDs of created private subnets"
  value       = aws_subnet.private[*].id
}


output "private_subnet_cidrs" {
  description = "The CIDR blocks of created private subnets"
  value       = aws_subnet.private[*].cidr_block
}


output "public_subnet_ids" {
  description = "The IDs of created public subnets"
  value       = aws_subnet.public[*].id
}


output "public_subnet_cidrs" {
  description = "The CIDR blocks of created public subnets"
  value       = aws_subnet.public[*].cidr_block
}


output "isolated_subnet_ids" {
  description = "The IDs of created isolated subnets"
  value       = aws_subnet.isolated[*].id
}


output "isolated_subnet_cidrs" {
  description = "The CIDR blocks of created isolated subnets"
  value       = aws_subnet.isolated[*].cidr_block
}


output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}


output "nat_gateway_ids" {
  description = "The IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}


output "private_route_table_ids" {
  description = "The IDs of the private route tables"
  value       = aws_route_table.private[*].id
}


output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}


output "isolated_route_table_id" {
  description = "The ID of the isolated route table"
  value       = var.isolated_subnets != null ? aws_route_table.isolated.id : null
}


output "default_security_group_id" {
  description = "The ID of the default security group"
  value       = aws_default_security_group.main.id
}


output "s3_gateway_endpoint_id" {
  description = "The ID of the S3 VPC Gateway Endpoint"
  value       = var.create_s3_gateway ? aws_vpc_endpoint.s3.id : null
}


output "dynamodb_gateway_endpoint_id" {
  description = "The ID of the DynamoDB VPC Gateway Endpoint"
  value       = var.create_dynamodb_gateway ? aws_vpc_endpoint.dynamodb.id : null
}
