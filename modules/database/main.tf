data "aws_rds_engine_version" "postgres" {
  engine  = "postgres"
  version = "17"
  latest  = true
}

resource "aws_db_subnet_group" "main" {
  name        = "terraform-3tier-${var.environment}-db-subnets"
  description = "Private database subnets for ${var.environment}."
  subnet_ids  = var.db_subnet_ids

  tags = {
    Name        = "terraform-3tier-${var.environment}-db-subnets"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "terraform-3tier-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = data.aws_rds_engine_version.postgres.version
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false

  multi_az                   = false
  backup_retention_period    = var.backup_retention_period
  auto_minor_version_upgrade = true

  deletion_protection = false
  skip_final_snapshot = true
  apply_immediately   = true

  tags = {
    Name        = "terraform-3tier-${var.environment}-postgres"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
