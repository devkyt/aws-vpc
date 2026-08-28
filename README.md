# AWS VPC

OpenTofu module for VPC provisioning. You can find how to use it in [example](./example/) folder
and in the [Examples](#examples) section below.

## Table of Contents

- [Requirements](#requirements)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Examples](#examples)
  - [Basic VPC](#basic-vpc)
  - [Isolated Subnets](#isolated-subnets)
  - [High Availability NAT](#high-availability-nat)
  - [Gateway Endpoints](#gateway-endpoints)
  - [S3 Gateway with Custom Policy](#s3-gateway-with-custom-policy)
  - [Flow Logs to CloudWatch](#flow-logs-to-cloudwatch)
  - [Flow Logs to S3](#flow-logs-to-s3)

## Requirements

| Name | Version |
|------|---------|
| OpenTofu | >= 1.11 |
| AWS provider | ~> 6.0  |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vpc_name` | VPC name | `string` | `""` | no |
| `project` | Project name | `string` | `"common"` | no |
| `env` | Target environment | `string` | - | yes |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `availability_zones` | Availability zones for subnets | `list(string)` | - | yes |
| `private_subnets` | Private subnets configuration | `object` | - | yes |
| `public_subnets` | Public subnets configuration | `object` | - | yes |
| `isolated_subnets` | Isolated subnets configuration | `object` | `null` | no |
| `high_availability_nat` | Deploy NAT in all AZs | `bool` | `false` | no |
| `create_s3_gateway` | Create S3 VPC Gateway Endpoint | `bool` | `false` | no |
| `s3_gateway_policy` | IAM policy document for S3 gateway endpoint | `string` | `null` | no |
| `create_dynamodb_gateway` | Create DynamoDB VPC Gateway Endpoint | `bool` | `false` | no |
| `dynamodb_gateway_policy` | IAM policy document for DynamoDB gateway endpoint | `string` | `null` | no |
| `flow_log` | VPC Flow Log configuration | `object` | `{}` | no |
| `cloudwatch_log_group` | CloudWatch Log Group configuration | `object` | `{}` | no |
| `use_name_prefix` | Use name_prefix instead of a fixed name for created resources, so AWS appends a unique suffix | `bool` | `false` | no |
| `include_default_tags` | Attach default tags | `bool` | `true` | no |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the VPC |
| `vpc_cidr` | The CIDR block of the VPC |
| `private_subnet_ids` | The IDs of private subnets |
| `private_subnet_cidrs` | The CIDR blocks of private subnets |
| `public_subnet_ids` | The IDs of public subnets |
| `public_subnet_cidrs` | The CIDR blocks of public subnets |
| `isolated_subnet_ids` | The IDs of isolated subnets |
| `isolated_subnet_cidrs` | The CIDR blocks of isolated subnets |
| `internet_gateway_id` | The ID of the Internet Gateway |
| `nat_gateway_ids` | The IDs of NAT Gateways |
| `private_route_table_ids` | The IDs of private route tables |
| `public_route_table_id` | The ID of the public route table |
| `isolated_route_table_id` | The ID of the isolated route table |
| `default_security_group_id` | The ID of the default security group |
| `s3_gateway_endpoint_id` | The ID of the S3 Gateway Endpoint |
| `dynamodb_gateway_endpoint_id` | The ID of the DynamoDB Gateway Endpoint |

## Examples

### Basic VPC

A minimal VPC with public and private subnets across two availability zones.

```hcl
module "vpc" {
  source = "git@github.com:devkyt/aws-vpc.git?ref=main&depth=1"

  vpc_name           = "my-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  env                = "experiment"

  private_subnets = {
    cidr_blocks = ["10.0.0.0/19", "10.0.32.0/19"]
    tags        = { For = "Private Access" }
  }

  public_subnets = {
    cidr_blocks = ["10.0.64.0/19", "10.0.96.0/19"]
    tags        = { For = "Public Access" }
  }
}
```

### Isolated Subnets

Adding isolated subnets with no internet access, useful for databases and internal services.

```hcl
module "vpc" {
  source = "git@github.com:devkyt/aws-vpc.git?ref=main&depth=1"

  vpc_name           = "prod-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  env                = "experiment"
  project            = "platform"

  private_subnets = {
    cidr_blocks = ["10.0.0.0/19", "10.0.32.0/19"]
    tags        = { For = "Private Access" }
  }

  public_subnets = {
    cidr_blocks = ["10.0.64.0/19", "10.0.96.0/19"]
    tags        = { For = "Public Access" }
  }

  isolated_subnets = {
    cidr_blocks = ["10.0.128.0/19", "10.0.160.0/19"]
    tags        = { For = "Isolated Environment" }
  }
}
```

### High Availability NAT

Deploying a NAT Gateway per availability zone for fault tolerance.

```hcl
module "vpc" {
  source = "git@github.com:devkyt/aws-vpc.git?ref=main&depth=1"

  vpc_name           = "ha-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  env                = "experiment"

  high_availability_nat = true

  private_subnets = {
    cidr_blocks = ["10.0.0.0/19", "10.0.32.0/19"]
    tags        = { For = "Private Access" }
  }

  public_subnets = {
    cidr_blocks = ["10.0.64.0/19", "10.0.96.0/19"]
    tags        = { For = "Public Access" }
  }
}
```

### Gateway Endpoints

Enabling S3 and DynamoDB gateway endpoints to keep traffic off the public internet.

```hcl
module "vpc" {
  source = "git@github.com:devkyt/aws-vpc.git?ref=main&depth=1"

  vpc_name           = "endpoint-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  env                = "experiment"

  private_subnets = {
    cidr_blocks = ["10.0.0.0/19", "10.0.32.0/19"]
    tags        = { For = "Private Access" }
  }

  public_subnets = {
    cidr_blocks = ["10.0.64.0/19", "10.0.96.0/19"]
    tags        = { For = "Public Access" }
  }

  create_s3_gateway       = true
  create_dynamodb_gateway = true
}
```

### S3 Gateway with Custom Policy

Restricting the S3 gateway endpoint to allow access only to a specific bucket.

```hcl
data "aws_iam_policy_document" "s3_gateway" {
  statement {
    sid    = "AllowAccessToSpecificBucket"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::my-app-bucket",
      "arn:aws:s3:::my-app-bucket/*",
    ]
  }
}

module "vpc" {
  source = "git@github.com:devkyt/aws-vpc.git?ref=main&depth=1"

  vpc_name           = "restricted-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  env                = "experiment"

  private_subnets = {
    cidr_blocks = ["10.0.0.0/19", "10.0.32.0/19"]
    tags        = { For = "Private Access" }
  }

  public_subnets = {
    cidr_blocks = ["10.0.64.0/19", "10.0.96.0/19"]
    tags        = { For = "Public Access" }
  }

  create_s3_gateway = true
  s3_gateway_policy = data.aws_iam_policy_document.s3_gateway.json
}
```

### Flow Logs to CloudWatch

Enabling VPC flow logs with an auto-created CloudWatch Log Group.

```hcl
module "vpc" {
  source = "git@github.com:devkyt/aws-vpc.git?ref=main&depth=1"

  vpc_name           = "observed-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  env                = "experiment"

  private_subnets = {
    cidr_blocks = ["10.0.0.0/19", "10.0.32.0/19"]
    tags        = { For = "Private Access" }
  }

  public_subnets = {
    cidr_blocks = ["10.0.64.0/19", "10.0.96.0/19"]
    tags        = { For = "Public Access" }
  }

  flow_log = {
    enable                      = true
    traffic_type                = "ALL"
    create_cloudwatch_log_group = true
  }

  cloudwatch_log_group = {
    retention_days = 30
  }
}
```

### Flow Logs to S3

Sending VPC flow logs to an S3 bucket with Parquet format and hourly partitions.

```hcl
module "vpc" {
  source = "git@github.com:devkyt/aws-vpc.git?ref=main&depth=1"

  vpc_name           = "audit-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b"]
  env                = "experiment"

  private_subnets = {
    cidr_blocks = ["10.0.0.0/19", "10.0.32.0/19"]
    tags        = { For = "Private Access" }
  }

  public_subnets = {
    cidr_blocks = ["10.0.64.0/19", "10.0.96.0/19"]
    tags        = { For = "Public Access" }
  }

  flow_log = {
    enable               = true
    traffic_type         = "ALL"
    log_destination_type = "s3"
    log_destination_arn  = "arn:aws:s3:::my-flow-logs-bucket"
    destination_options = {
      file_format        = "parquet"
      per_hour_partition = true
    }
  }
}
```

## License

Licensed under the Apache License, Version 2.0.

Copyright 2026 Kyrylo Tykhanskyi.
