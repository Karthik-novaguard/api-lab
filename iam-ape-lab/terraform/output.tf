output "all_users" {
  value = keys(aws_iam_user.all_users)
}

output "alice_access_keys" { # <-- CHANGED
  value = {
    access_key_id     = aws_iam_access_key.alice_key.id # <-- CHANGED
    secret_access_key = aws_iam_access_key.alice_key.secret # <-- CHANGED
  }
  sensitive = true
}

output "bob_access_keys" { # <-- CHANGED
  value = {
    access_key_id     = aws_iam_access_key.bob_key.id # <-- CHANGED
    secret_access_key = aws_iam_access_key.bob_key.secret # <-- CHANGED
  }
  sensitive = true
}

output "john_access_keys" { # <-- CHANGED
  value = {
    access_key_id     = aws_iam_access_key.john_key.id # <-- CHANGED
    secret_access_key = aws_iam_access_key.john_key.secret # <-- CHANGED
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