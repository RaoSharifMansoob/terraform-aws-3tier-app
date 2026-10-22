variable "environment" {
  description = "Environment name, such as dev or prod."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the load balancer will be created."
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets used by the load balancer."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID attached to the load balancer."
  type        = string
}
