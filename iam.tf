# ---------------------------------------------
# IAM Role Assumed By VPC Flow Logs
# ---------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid = "VpcFlowLogAssumeRole"

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

  lifecycle {
    enabled = local.create_cloudwatch
  }
}


# Assumed by the VPC Flow Logs service to deliver flow records to CloudWatch Logs
resource "aws_iam_role" "main" {
  name        = var.use_name_prefix ? null : local.cloudwatch_log_group_role_name
  name_prefix = var.use_name_prefix ? "${local.cloudwatch_log_group_role_name}-" : null

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(local.tags,
    {
      Name = local.cloudwatch_log_group_role_name
      Type = "IAM Role"
    }
  )

  lifecycle {
    create_before_destroy = true
    enabled               = local.create_cloudwatch
  }
}


# ---------------------------------------------
# IAM Policy Allowing Flow Log Writes To CloudWatch
# ---------------------------------------------
data "aws_iam_policy_document" "write_logs" {
  statement {
    sid = "VpcFlowLogWriteLogsToCloudwatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = [
      aws_cloudwatch_log_group.main.arn,
      "${aws_cloudwatch_log_group.main.arn}:log-stream:*"
    ]
  }

  lifecycle {
    enabled = local.create_cloudwatch
  }
}


resource "aws_iam_policy" "write_logs" {
  name        = var.use_name_prefix ? null : "${local.cloudwatch_log_group_role_name}-policy"
  name_prefix = var.use_name_prefix ? "${local.cloudwatch_log_group_role_name}-policy-" : null
  policy      = data.aws_iam_policy_document.write_logs.json

  tags = merge(local.tags,
    {
      Name = "${local.cloudwatch_log_group_role_name}-policy"
      Type = "IAM Policy"
    }
  )

  lifecycle {
    create_before_destroy = true
    enabled               = local.create_cloudwatch
  }
}


# ---------------------------------------------
# Attach The Flow Log Write Policy To The Role
# ---------------------------------------------
resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.write_logs.arn

  lifecycle {
    enabled = local.create_cloudwatch
  }
}
