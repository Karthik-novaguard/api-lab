output "all_users" {
  value = keys(aws_iam_user.all_users)
}

output "over_user1_access_keys" {
  value = {
    access_key_id     = aws_iam_access_key.over_user1_key.id
    secret_access_key = aws_iam_access_key.over_user1_key.secret
  }
  sensitive = true
}

output "least_user1_access_keys" {
  value = {
    access_key_id     = aws_iam_access_key.least_user1_key.id
    secret_access_key = aws_iam_access_key.least_user1_key.secret
  }
  sensitive = true
}

output "ineff_user1_access_keys" {
  value = {
    access_key_id     = aws_iam_access_key.ineff_user1_key.id
    secret_access_key = aws_iam_access_key.ineff_user1_key.secret
  }
  sensitive = true
}

output "resources_summary" {
  value = {
    s3_bucket = aws_s3_bucket.lab_bucket.bucket
    dynamodb  = aws_dynamodb_table.lab_table.name
    ec2       = aws_instance.lab_ec2.id
    lambda    = aws_lambda_function.lab_function.function_name
    secret    = aws_secretsmanager_secret.lab_secret.name
  }
}