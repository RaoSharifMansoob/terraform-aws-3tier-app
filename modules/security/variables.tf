variable "environment" {
  description = "Environment name, such as dev or prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created."
  type        = string
}
