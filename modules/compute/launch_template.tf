resource "aws_launch_template" "app" {
  name_prefix   = "terraform-3tier-${var.environment}-"
  image_id      = "ami-0b1743fd5dca8aa9b"
  instance_type = var.instance_type

  vpc_security_group_ids = [var.app_security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "terraform-3tier-${var.environment}-app"
      Project     = "terraform-aws-3tier-app"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name        = "terraform-3tier-${var.environment}-app-volume"
      Project     = "terraform-aws-3tier-app"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }

  tags = {
    Name        = "terraform-3tier-${var.environment}-launch-template"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    create_before_destroy = true
  }
}
