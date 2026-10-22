variable "environment" {
  description = "Environment name, such as dev or prod."
  type        = string
}

variable "app_subnet_ids" {
  description = "Private application subnet IDs for the Auto Scaling Group."
  type        = list(string)

  validation {
    condition     = length(var.app_subnet_ids) >= 2
    error_message = "At least two application subnet IDs must be provided."
  }
}

variable "app_security_group_id" {
  description = "Security group ID attached to application instances."
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the ALB target group."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances."
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of EC2 instances."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances."
  type        = number
  default     = 2
}
