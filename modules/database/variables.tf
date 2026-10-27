variable "environment" {
  description = "Environment name, such as dev or prod."
  type        = string
}

variable "db_subnet_ids" {
  description = "Private subnet IDs for the RDS subnet group."
  type        = list(string)

  validation {
    condition     = length(var.db_subnet_ids) >= 2
    error_message = "At least two database subnet IDs must be provided."
  }
}

variable "db_security_group_id" {
  description = "Security group ID assigned to the RDS instance."
  type        = string
}

variable "db_name" {
  description = "Initial PostgreSQL database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for PostgreSQL."
  type        = string
  default     = "appadmin"
}

variable "db_instance_class" {
  description = "RDS DB instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Allocated database storage in GiB."
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Automated backup retention period in days."
  type        = number
  default     = 1
}
