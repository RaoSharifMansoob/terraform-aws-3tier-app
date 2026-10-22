
variable "environment" {
  description = "Environment name, such as dev or prod."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Two AWS availability zones for the subnets."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two availability zones must be provided."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs must be provided."
  }
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for the private application subnets."
  type        = list(string)

  validation {
    condition     = length(var.app_subnet_cidrs) == 2
    error_message = "Exactly two application subnet CIDRs must be provided."
  }
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for the private database subnets."
  type        = list(string)

  validation {
    condition     = length(var.db_subnet_cidrs) == 2
    error_message = "Exactly two database subnet CIDRs must be provided."
  }
}
