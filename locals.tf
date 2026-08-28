locals {
  project = coalesce(var.project, "vpc")

  vpc_name = coalesce(var.vpc_name, "${local.project}-${var.env}")

  create_cloudwatch              = var.flow_log.enable && var.flow_log.create_cloudwatch_log_group
  cloudwatch_log_group_name      = coalesce(var.cloudwatch_log_group.name, "vpc/${local.vpc_name}")
  cloudwatch_log_group_role_name = coalesce(var.cloudwatch_log_group.iam_role_name, "${local.vpc_name}-flow-logs")

  flow_log_iam_role_arn    = local.create_cloudwatch ? aws_iam_role.main.arn : try(coalesce(var.flow_log.iam_role_arn, data.aws_iam_role.flow_log.arn), null)
  flow_log_destination_arn = local.create_cloudwatch ? aws_cloudwatch_log_group.main.arn : var.flow_log.log_destination_arn

  route_table_ids_for_gateway_endpoints = concat(
    aws_route_table.private[*].id,
    var.isolated_subnets != null ? aws_route_table.isolated[*].id : []
  )

  default_tags = var.include_default_tags ? {
    Project     = var.project
    Environment = var.env
    Env         = var.env
    VPC         = local.vpc_name
    Terraform   = "true"
    ManagedBy   = "Terraform"
  } : {}

  tags = merge(local.default_tags, var.tags)
}
