#
#  ETM Application Stack
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
# ************ Lambda Dependencies ************
# *********************************************

# Zip the lambda if unzipped out of build process
data "archive_file" "zipped_lambda" {
  type        = "zip"
  source_file = "etm-prototype-dvmc"
  output_path = "etm-prototype-dvmc.zip"
}

# Create the Lambda Trust Policy
data "aws_iam_policy_document" "lambda_trust_policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create the Lambda IAM Role
resource "aws_iam_role" "iam_for_lambda" {
  name               = "ETM-LambdaExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_policy.json
  tags               = var.default_tags
}


# Attach pre-existing Basic Exec Policy
data "aws_iam_policy" "lambda_basic_exec_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "lambda_policy_attachmnet_basic_exec" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}

# Attach a policy to allow the Lambda to create its ENIs
data "aws_iam_policy_document" "create_network_interfaces_policy_document" {
 statement {
   actions = [
              "ec2:CreateNetworkInterface",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DetachNetworkInterface",
              "ec2:DeleteNetworkInterface"
   ]
   resources = ["*"]
 }
}

resource "aws_iam_policy" "create_network_interfaces_policy" {
  name   = "ETM-CreateNetworkInterfacesForLambdaPolicy"
  policy = data.aws_iam_policy_document.create_network_interfaces_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_eni" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.create_network_interfaces_policy.arn
}


# Attach a policy to allow the Lambda to interact with its DDB table
data "aws_iam_policy_document" "allow_ddb_read_write_policy_document" {
 statement {
   actions = [
     "dynamodb:BatchGetItem",
     "dynamodb:BatchWriteItem",
     "dynamodb:DeleteItem",
     "dynamodb:GetItem",
     "dynamodb:Query",
     "dynamodb:Scan",
     "dynamodb:UpdateItem",
     "dynamodb:*"
   ]
   resources = [
     "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.ddb_orders_table_name}",
     "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/etm-orders-conahfc-sample-stack",
     "*"
   ]
 }
}

resource "aws_iam_policy" "allow_ddb_read_write_policy" {
  name   = "ETM-ReadWriteToDDB-OrdersTable"
  policy = data.aws_iam_policy_document.allow_ddb_read_write_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_ddb" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.allow_ddb_read_write_policy.arn
}


# Create the VPCE security group if Lambda will be VPC private
#Note this controls access to the *Lambda* but enforces at the *endpoint*
resource "aws_security_group" "ETM-LambdaEndpointSecurityGroup" {
  name        = "ETM-LambdaEndpointSG"
  vpc_id      = data.aws_vpc.my_vpc.id
  description = "Allow all privte traffic to/from endpoint"

  ingress {
    description = "All private traffic from VPC to Lambda"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.my_vpc.cidr_block]
  }

  egress {
    description = "All private traffic from Lambda to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = list(data.aws_vpc.my_vpc.cidr_block)
  }

  tags = var.default_tags
}


# *********************************************
# ************ Lambda Function ****************
# *********************************************

# Reference: https://www.terraform.io/docs/providers/aws/r/lambda_function.html
resource "aws_lambda_function" "stocksapp_lambda" {

  function_name = "ETM-Prototype-DVMC"
  filename      = "etm-prototype-dvmc.zip"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "Etm.API::Etm.API.LambdaEntryPoint::FunctionHandlerAsync"
  runtime       = "dotnetcore3.1"
  memory_size   = "256"
  timeout       = "30"

  # Uncomment the following to make this a VPC-private lambda
  vpc_config {
    subnet_ids          = list(data.aws_subnet.private_subnet2.id)
    security_group_ids  = list(aws_security_group.ETM-LambdaEndpointSecurityGroup.id)
  }

  tags = var.default_tags
}



# *********************************************
# ************ API Gateway ********************
#
# access at vpce-0ed08faa76d7ce00f
# https://1kk32pr170.vpce-0ed08faa76d7ce00f.execute-api.us-west-2.amazonaws.com/dev/stock
# *********************************************
resource "aws_api_gateway_rest_api" "api" {

    name = "StocksAPI"
    endpoint_configuration {
      types             = ["PRIVATE"]
      vpc_endpoint_ids  = var.api_endpoint_ids
    }

    #note: the following allows private VPC traffic from all principals
    policy = <<POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": "*",
              "Action": "execute-api:Invoke",
              "Resource": ["*"]
          }
      ]
   }
   POLICY

   tags = var.default_tags
}


resource "aws_api_gateway_resource" "stock_resource" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.api.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "stock_resource_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.stock_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

# DVMC: The integration_http_method MUST be POST even if method is GET
resource "aws_api_gateway_integration" "stock_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.stock_resource.id
  http_method             = aws_api_gateway_method.stock_resource_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.stocksapp_lambda.invoke_arn
}

resource "aws_lambda_permission" "apigw_to_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stocksapp_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.stock_resource_get_method.http_method}${aws_api_gateway_resource.stock_resource.path}"
}
