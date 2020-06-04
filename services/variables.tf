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

variable "private_route_table_id" {
  default = "rtb-0ed0ce12f9ce7e4b7"
}

variable "stack_id" {
  default = "dvmc"
}

# Tag values for this account
variable "default_tags" {
    type = map(string)
    default = {
        cost-center: "524121",
        env-type:    "accounting",
        exp-date:    "99-00-9999",
        ppmc-id:     "74161",
        sd-period:   "na",
        site:        "aws",
        toc:         "ETOC",
        usage-id:    "network"
    }
}
