output "vpc_id" {
  description = "VPC ID for the prod environment."
  value       = module.networking.vpc_id
}

output "alb_url" {
  description = "HTTP URL for the prod application."
  value       = module.load_balancer.alb_url
}

output "autoscaling_group_name" {
  description = "Prod application Auto Scaling Group."
  value       = module.compute.autoscaling_group_name
}

output "rds_endpoint" {
  description = "Prod PostgreSQL endpoint."
  value       = module.database.rds_endpoint
}

output "rds_port" {
  description = "Prod PostgreSQL port."
  value       = module.database.rds_port
}
