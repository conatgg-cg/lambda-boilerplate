
output "account_id" {
  value = "data.aws_caller_identity.current.account_id"
}

output "region" {
  value = "data.aws_region.current.name"
}

output "private_subnet1_id" {
  value = "aws_subnet.private_subnet1.id"
}

output "private_subnet2_id" {
  value = "aws_subnet.private_subnet2.id"
}

output "api_vpc_endpoint_id" {
  value = "aws_vpc_endpoint.api_endpoint.id"
}
