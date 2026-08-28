output "vpc_id" {
  description = "The ID of created VPC"
  value       = module.vpc.vpc_id
}


output "private_subnet_ids" {
  description = "The IDs of created private subnets"
  value       = module.vpc.private_subnet_ids
}


output "public_subnet_ids" {
  description = "The IDs of created public subnets"
  value       = module.vpc.public_subnet_ids
}


output "s3_gateway_endpoint_id" {
  description = "The ID of the S3 VPC Gateway Endpoint"
  value       = module.vpc.s3_gateway_endpoint_id
}


output "dynamodb_gateway_endpoint_id" {
  description = "The ID of the DynamoDB VPC Gateway Endpoint"
  value       = module.vpc.dynamodb_gateway_endpoint_id
}
