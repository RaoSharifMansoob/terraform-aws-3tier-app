output "autoscaling_group_name" {
  description = "Name of the application Auto Scaling Group."
  value       = aws_autoscaling_group.app.name
}

output "iam_role_name" {
  description = "Name of the EC2 IAM role."
  value       = aws_iam_role.ec2.name
}

output "launch_template_id" {
  description = "ID of the application launch template."
  value       = aws_launch_template.app.id
}
