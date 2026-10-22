variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "The dev root must use environment = dev."
  }
}

variable "availability_zones" {
  description = "Two availability zones for the environment."
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the dev VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs."
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "Private application subnet CIDRs."
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "Private database subnet CIDRs."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired EC2 instance count."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum EC2 instance count."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum EC2 instance count."
  type        = number
  default     = 2
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "appadmin"
}

variable "db_password" {
  description = "PostgreSQL master password."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GiB."
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "RDS automated backup retention in days."
  type        = number
  default     = 1
}
