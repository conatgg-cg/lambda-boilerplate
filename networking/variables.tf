variable "region" {
  description = "The name of the AWS region to set up a network within"
  default = "us-west-2"
}
variable "vpc_id" {
  description = "Id of the pre-existing VPC created with the account"
  default = "vpc-0d9ea21bb64376edb"
}
variable "private_subnet1_id" {
  default = "subnet-01d4bb9795a9a25a4"
}
variable "private_subnet2_id" {
  default = "subnet-079559865203dd327"
}

# Tag values for this account
variable "tag_value_cost_center" { default = "524121"}
variable "tag_value_env_type" { default = "dev"}
variable "tag_value_exp_date" { default = "99-00-9999"}
variable "tag_value_ppmc_id" { default = "74161"}
variable "tag_value_sd_period" { default = "na"}
variable "tag_value_site" { default = "aws"}
variable "tag_value_toc" { default = "ETOC"}
variable "tag_value_usage_id" { default = "network"}
