output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "IDs of the private application subnets."
  value       = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "IDs of the private database subnets."
  value       = aws_subnet.db[*].id
}
