output "target_group_arn" {
  description = "ARN of the target group used by the application instances."
  value       = aws_lb_target_group.app.arn
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer."
  value       = aws_lb.app.dns_name
}

output "alb_url" {
  description = "HTTP URL of the application load balancer."
  value       = "http://${aws_lb.app.dns_name}"
}
