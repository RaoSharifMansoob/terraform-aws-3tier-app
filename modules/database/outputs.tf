output "rds_endpoint" {
  description = "Hostname of the PostgreSQL database."
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Port of the PostgreSQL database."
  value       = aws_db_instance.postgres.port
}

output "rds_identifier" {
  description = "Identifier of the RDS instance."
  value       = aws_db_instance.postgres.identifier
}
