output "alb_security_group_id" {
  description = "Security group ID for the application load balancer."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for the application instances."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "Security group ID for the database."
  value       = aws_security_group.db.id
}
