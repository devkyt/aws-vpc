# ---------------------------------------------
# Current AWS Region
# ---------------------------------------------
data "aws_region" "current" {}


# ---------------------------------------------
# Existing IAM Role For Flow Log Delivery
# ---------------------------------------------
data "aws_iam_role" "flow_log" {
  name = var.flow_log.iam_role_name

  lifecycle {
    enabled = var.flow_log.enable && !local.create_cloudwatch && var.flow_log.iam_role_name != null
  }
}
