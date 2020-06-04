
# The AWS "provider" instantiates resources
provider "aws" {
  region = "${var.region}"
}

# data object for getting to the "current" account
data "aws_caller_identity" "current" {}
# data object for getting to the "current" region
data "aws_region" "current" {}

#
# VPC and Subnets
#
data "aws_vpc" "my_vpc" {
  id = "${var.vpc_id}"
}

#
# Subnets
#
data "aws_subnet" "private_subnet1" {
  id = "${var.private_subnet1_id}"
}

data "aws_subnet" "private_subnet2" {
  id = "${var.private_subnet2_id}"
}

#
# Routes (currently using routes defined in original VPC setup)
#


#
# Security groups
#
resource "aws_security_group" "api_endpoint_security_group" {
  name        = "ETM_API_Endpoint_SG"
  vpc_id      = "${data.aws_vpc.my_vpc.id}"
  description = "Allow https traffic to endpoint"

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.my_vpc.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ETM-APIEndpointSecurityGroup",
    cost-center = var.tag_value_cost_center,
    env-type    = var.tag_value_env_type,
    exp-date    = var.tag_value_exp_date,
    ppmc-id     = var.tag_value_ppmc_id,
    sd-period   = var.tag_value_sd_period,
    site        = var.tag_value_site,
    toc         = var.tag_value_toc,
    usage-id    = var.tag_value_usage_id
  }
}

resource "aws_vpc_endpoint" "api_endpoint" {
  vpc_id              = "${data.aws_vpc.my_vpc.id}"
  service_name        = "com.amazonaws.us-west-2.execute-api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = ["${aws_security_group.api_endpoint_security_group.id}"]

  tags = {
    Name        = "ETM-APIEndpoint",
    cost-center = var.tag_value_cost_center,
    env-type    = var.tag_value_env_type,
    exp-date    = var.tag_value_exp_date,
    ppmc-id     = var.tag_value_ppmc_id,
    sd-period   = var.tag_value_sd_period,
    site        = var.tag_value_site,
    toc         = var.tag_value_toc,
    usage-id    = var.tag_value_usage_id
  }
}

resource "aws_vpc_endpoint_subnet_association" "api_endpoint_to_private_subnet_assn" {
    vpc_endpoint_id = aws_vpc_endpoint.api_endpoint.id
    subnet_id       = data.aws_subnet.private_subnet1.id
}
