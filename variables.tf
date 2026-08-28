variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]*$", var.vpc_name))
    error_message = "VPC name must contain only letters, numbers, hyphens, and underscores."
  }
}


variable "project" {
  description = "Project for which VPC will be used"
  type        = string
  default     = "common"

  validation {
    condition     = length(var.project) > 0
    error_message = "Project name cannot be empty."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "env" {
  description = "Target environment"
  type        = string

  validation {
    condition     = length(var.env) > 0
    error_message = "Environment cannot be empty."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.env))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}


variable "vpc_cidr" {
  description = "CIDR (Classless Inter-Domain Routing) block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr))
    error_message = "VPC CIDR must be in valid format (e.g., 10.0.0.0/16)."
  }
}


variable "availability_zones" {
  description = "Availability zones for the subnets"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) > 0
    error_message = "At least one availability zone must be specified."
  }

  validation {
    condition     = alltrue([for az in var.availability_zones : can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", az))])
    error_message = "All availability zones must be in valid AWS format (e.g., us-east-1a, eu-west-1b)."
  }
}


variable "private_subnets" {
  description = "Private subnets configuration"
  type = object({
    cidr_blocks = list(string)
    tags        = map(string)
  })

  validation {
    condition     = length(var.private_subnets.cidr_blocks) > 0
    error_message = "At least one private subnet CIDR block must be specified."
  }

  validation {
    condition     = alltrue([for cidr in var.private_subnets.cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All private subnet CIDR blocks must be valid IPv4 CIDR blocks."
  }
}


variable "public_subnets" {
  description = "Public subnets configuration"
  type = object({
    cidr_blocks = list(string)
    tags        = map(string)
  })

  validation {
    condition     = length(var.public_subnets.cidr_blocks) > 0
    error_message = "At least one public subnet CIDR block must be specified."
  }

  validation {
    condition     = alltrue([for cidr in var.public_subnets.cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All public subnet CIDR blocks must be valid IPv4 CIDR blocks."
  }
}


variable "isolated_subnets" {
  description = "Isolated subnets configuration"
  type = object({
    cidr_blocks = list(string)
    tags        = map(string)
  })
  default = null

  validation {
    condition     = var.isolated_subnets == null ? true : length(var.isolated_subnets.cidr_blocks) > 0
    error_message = "At least one isolated subnet CIDR block must be specified."
  }

  validation {
    condition     = var.isolated_subnets == null ? true : alltrue([for cidr in var.isolated_subnets.cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "All isolated subnet CIDR blocks must be valid IPv4 CIDR blocks."
  }
}


variable "high_availability_nat" {
  description = "Ensure NAT deployed in all Availability Zones"
  type        = bool
  default     = false
}


variable "flow_log" {
  description = "VPC Flow Log configuration"
  type = object({
    enable                      = optional(bool, false)
    traffic_type                = optional(string, "ALL")
    log_destination_type        = optional(string, "cloud-watch-logs")
    log_destination_arn         = optional(string)
    log_format                  = optional(string)
    iam_role_arn                = optional(string)
    iam_role_name               = optional(string)
    cross_account_role_arn      = optional(string)
    aggregation_interval_sec    = optional(number, 600)
    create_cloudwatch_log_group = optional(bool, false)
    destination_options = optional(object({
      file_format                = optional(string, "plain-text")
      hive_compatible_partitions = optional(bool, false)
      per_hour_partition         = optional(bool, false)
    }), {})
  })
  default = {}

  validation {
    condition     = !var.flow_log.enable || var.flow_log.log_destination_type != "cloud-watch-logs" || var.flow_log.create_cloudwatch_log_group || var.flow_log.iam_role_arn != null || var.flow_log.iam_role_name != null
    error_message = "When using cloud-watch-logs destination with create_cloudwatch_log_group set to false, either iam_role_arn or iam_role_name must be provided."
  }

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_log.traffic_type)
    error_message = "traffic_type must be one of: ACCEPT, REJECT, ALL."
  }

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log.log_destination_type)
    error_message = "log_destination_type must be one of: cloud-watch-logs, s3."
  }

  validation {
    condition     = contains([60, 600], var.flow_log.aggregation_interval_sec)
    error_message = "aggregation_interval_sec must be 60 or 600."
  }

  validation {
    condition     = !var.flow_log.enable || var.flow_log.create_cloudwatch_log_group || var.flow_log.log_destination_arn != null
    error_message = "log_destination_arn must be provided when create_cloudwatch_log_group is false and flow log is enabled."
  }

  validation {
    condition     = var.flow_log.destination_options == null || var.flow_log.destination_options.file_format == null || contains(["plain-text", "parquet"], var.flow_log.destination_options.file_format)
    error_message = "destination_options.file_format must be one of: plain-text, parquet."
  }

  validation {
    condition     = var.flow_log.iam_role_arn == null || can(regex("^arn:aws:iam::", var.flow_log.iam_role_arn))
    error_message = "iam_role_arn must be a valid IAM role ARN."
  }

  validation {
    condition     = var.flow_log.cross_account_role_arn == null || can(regex("^arn:aws:iam::", var.flow_log.cross_account_role_arn))
    error_message = "cross_account_role_arn must be a valid IAM role ARN."
  }
}


variable "cloudwatch_log_group" {
  description = "CloudWatch Log Group to use as destination for VPC Flow Logs"
  type = object({
    name            = optional(string)
    iam_role_name   = optional(string)
    retention_days  = optional(number, 14)
    kms_key_id      = optional(string)
    skip_destroy    = optional(bool, false)
    log_group_class = optional(string)
  })
  default = {}

  validation {
    condition     = var.cloudwatch_log_group.retention_days == null || contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_log_group.retention_days)
    error_message = "retention_days must be a valid CloudWatch Log Group retention value (0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653)."
  }

  validation {
    condition     = var.cloudwatch_log_group.log_group_class == null || contains(["STANDARD", "INFREQUENT_ACCESS"], var.cloudwatch_log_group.log_group_class)
    error_message = "log_group_class must be one of: STANDARD, INFREQUENT_ACCESS."
  }

  validation {
    condition     = var.cloudwatch_log_group.kms_key_id == null || can(regex("^arn:aws:kms:", var.cloudwatch_log_group.kms_key_id))
    error_message = "kms_key_id must be a valid KMS key ARN."
  }
}


variable "create_s3_gateway" {
  description = "Whether to create an S3 VPC Gateway Endpoint"
  type        = bool
  default     = false
}


variable "s3_gateway_policy" {
  description = "IAM policy document for the S3 gateway endpoint"
  type        = string
  default     = null
}


variable "create_dynamodb_gateway" {
  description = "Whether to create a DynamoDB VPC Gateway Endpoint"
  type        = bool
  default     = false
}


variable "dynamodb_gateway_policy" {
  description = "IAM policy document for the DynamoDB gateway endpoint"
  type        = string
  default     = null
}


variable "use_name_prefix" {
  description = "Use name_prefix instead of a fixed name for the resources this module creates, so AWS appends a unique suffix"
  type        = bool
  default     = false
}


variable "include_default_tags" {
  description = "Whether or not to attach default tags specified in module"
  type        = bool
  default     = true
}


variable "tags" {
  description = "Tags to apply to the VPC and related resources"
  type        = map(string)
  default     = {}
}
