resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "terraform-3tier-${var.environment}-igw"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
