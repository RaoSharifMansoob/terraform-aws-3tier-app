output "vpc_id" {
  description = "ID of the project VPC."
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = aws_lb.app.dns_name
}

output "alb_url" {
  description = "HTTP URL of the application load balancer."
  value       = "http://${aws_lb.app.dns_name}"
}

output "app_security_group_id" {
  description = "Security group ID of the application tier."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security group ID of the database tier."
  value       = aws_security_group.db.id
}

output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL database."
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Port of the PostgreSQL database."
  value       = aws_db_instance.postgres.port
}
