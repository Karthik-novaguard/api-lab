output "lab_user_arns" {
  description = "ARNs of the created IAM lab users"
  value       = { for u in aws_iam_user.lab_users : u.name => u.arn }
}