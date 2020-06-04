
#  ETM Services Stack
#

#
# VPC and Subnets
#
data "aws_vpc" "my_vpc" {
  id = var.vpc_id
}

data "aws_subnet" "private_subnet1" {
  id = var.private_subnet1_id
}

data "aws_subnet" "private_subnet2" {
  id = var.private_subnet2_id
}

data "aws_kms_key" "ddb_encryption_key" {
  key_id = "alias/aws-etm-dev/uswest2/rds/0/kek"
}
#
# Providers
#
provider "aws" {
  region = "us-west-2"
}
#
# Account and region
#
# "current" account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


# *********************************************
# ******** DDB VPC Endpoint (Gateway type) ****
# *********************************************
# TODO: Narrow down the  DDB endpoint policy
resource "aws_vpc_endpoint" "ddb_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = list(var.private_route_table_id)

  policy = <<POLICY
   {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "DynamoDB:*",
            "Resource": ["*"]
        }
    ]
   }
  POLICY


  tags = merge(
                map(
                  "Name", "ETM-DDB-Endpoint"
                ),
                var.default_tags
              )

}

# Note: this will route ALL DDB from subnets tied to this route table through the endpoint
resource "aws_vpc_endpoint_route_table_association" "dynamodb" {
     vpc_endpoint_id = aws_vpc_endpoint.ddb_endpoint.id
     route_table_id  = var.private_route_table_id
}

# *********************************************
# ************ DDB tables *********************
# *********************************************

resource "aws_dynamodb_table" "etm-orders-dvmc-sample-stack" {
  name           = "etm-orders-${var.stack_id}-sample-stack"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PrimaryHashKey"
  range_key      = "PrimaryRangeKey"

  server_side_encryption {
    enabled = true
    kms_key_arn = data.aws_kms_key.ddb_encryption_key.arn
  }

  attribute {
    name = "PrimaryHashKey"
    type = "N"
  }

  attribute {
    name = "PrimaryRangeKey"
    type = "S"
  }

  attribute {
    name = "PPortfolioId"
    type = "N"
  }

  attribute {
    name = "TType_ListingId"
    type = "S"
  }

  attribute {
    name = "ListingId"
    type = "N"
  }

  attribute {
    name = "PPType_TType"
    type = "S"
  }

  global_secondary_index {
    name               = "PortfolioGSI"
    hash_key           = "PPortfolioId"
    range_key          = "TType_ListingId"
    projection_type    = "ALL"
  }

  global_secondary_index {
    name               = "ListingGSI"
    hash_key           = "ListingId"
    range_key          = "PPType_TType"
    projection_type    = "ALL"
  }

  tags = var.default_tags
}
