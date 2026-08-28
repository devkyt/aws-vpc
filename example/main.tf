locals {
  env    = "experiment"
  region = "eu-central-1"

  tags = {
    Team   = "Research and Development"
    Office = "Hamburg"
  }
}


terraform {
  backend "s3" {
    bucket = "terraform-experiments-state"
    region = "eu-central-1"
    key    = "vpc/terraform.tfstate"
  }
}


provider "aws" {
  region = local.region
}


module "vpc" {
  source = "git@github.com:devkyt/aws-vpc.git?ref=main&depth=1"

  vpc_name           = "alpha-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1b", "eu-central-1c"]
  env                = local.env

  private_subnets = {
    # The number of cidr blocks must be equal to the number of availability zones
    cidr_blocks = ["10.0.0.0/19", "10.0.32.0/19"]
    tags = {
      For = "Private Access"
    }
  }

  public_subnets = {
    # The number of cidr blocks must be equal to the number of availability zones
    cidr_blocks = ["10.0.64.0/19", "10.0.96.0/19"]
    tags = {
      For = "Public Access"
    }
  }

  # Optional. Can be omitted
  isolated_subnets = {
    # The number of cidr blocks must be equal to the number of availability zones
    cidr_blocks = ["10.0.128.0/19", "10.0.160.0/19"]
    tags = {
      For = "Isolated Environment"
    }
  }

  # Optional. VPC Gateway Endpoints
  create_s3_gateway       = true
  create_dynamodb_gateway = true

  tags = local.tags
}
