output "vpc_id" {
  description = "VPC ID for the dev environment."
  value       = module.networking.vpc_id
}

output "alb_url" {
  description = "HTTP URL for the dev application."
  value       = module.load_balancer.alb_url
}

output "autoscaling_group_name" {
  description = "Dev application Auto Scaling Group."
  value       = module.compute.autoscaling_group_name
}

output "rds_endpoint" {
  description = "Dev PostgreSQL endpoint."
  value       = module.database.rds_endpoint
}

output "rds_port" {
  description = "Dev PostgreSQL port."
  value       = module.database.rds_port
}
