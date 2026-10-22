provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "terraform-aws-3tier-app"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
