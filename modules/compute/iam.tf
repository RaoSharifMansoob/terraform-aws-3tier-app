resource "aws_iam_role" "ec2" {
  name = "terraform-3tier-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "terraform-3tier-${var.environment}-ec2-role"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_instance_profile" "ec2" {
  name = "terraform-3tier-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name        = "terraform-3tier-${var.environment}-ec2-profile"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
