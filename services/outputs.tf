

output "ddb_table_arn" {
  value = aws_dynamodb_table.etm-orders-dvmc-sample-stack.arn
}


#output "gateway_execute_endpoint" {
#  value = "${aws_api_gateway_rest_api.api.execution_arn}"
#}
