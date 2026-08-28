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
