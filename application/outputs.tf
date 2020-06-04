
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "lambda_arn" {
  value = aws_lambda_function.stocksapp_lambda.arn
}

output "region" {
  value = data.aws_region.current.name
}

#output "gateway_execute_endpoint" {
#  value = "${aws_api_gateway_rest_api.api.execution_arn}"
#}
