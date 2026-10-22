resource "aws_security_group" "alb" {
  name        = "terraform-3tier-${var.environment}-alb-sg"
  description = "Allow public HTTP traffic to the application load balancer."
  vpc_id      = var.vpc_id

  egress = []

  tags = {
    Name        = "terraform-3tier-${var.environment}-alb-sg"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP traffic from the internet."
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow outbound traffic to application instances."
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_security_group" "app" {
  name        = "terraform-3tier-${var.environment}-app-sg"
  description = "Allow HTTP traffic only from the load balancer."
  vpc_id      = var.vpc_id

  egress = []

  tags = {
    Name        = "terraform-3tier-${var.environment}-app-sg"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow HTTP traffic from the ALB."
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow PostgreSQL traffic to the database."
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.db.id
}

resource "aws_security_group" "db" {
  name        = "terraform-3tier-${var.environment}-db-sg"
  description = "Allow PostgreSQL traffic only from application instances."
  vpc_id      = var.vpc_id

  egress = []

  tags = {
    Name        = "terraform-3tier-${var.environment}-db-sg"
    Project     = "terraform-aws-3tier-app"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_postgres" {
  security_group_id            = aws_security_group.db.id
  description                  = "Allow PostgreSQL traffic from application instances."
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.app.id
}
