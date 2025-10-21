terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  required_version = ">= 1.4.0"
}

provider "aws" {
  region  = "us-west-2"
  profile = "admin-ape"
}

# ----------------- IAM Groups -----------------
resource "aws_iam_group" "overperm_group" {
  name = "GroupOverPerm"
}

resource "aws_iam_group" "leastperm_group" {
  name = "GroupLeastPerm"
}

resource "aws_iam_group" "ineffective_group" {
  name = "GroupIneffectivePerm"
}

# ----------------- IAM Policies -----------------
# Over-permissioned group - Admin access
resource "aws_iam_group_policy_attachment" "overperm_admin" {
  group      = aws_iam_group.overperm_group.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# OverUser Custom Restrictions
resource "aws_iam_group_policy" "overperm_custom" {
  name  = "OverPermCustomPolicy"
  group = aws_iam_group.overperm_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Deny S3 delete actions
      {
        Effect   = "Deny"
        Action   = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteBucket"
        ]
        Resource = "*"
      },
      # Deny EC2 destructive/write actions
      {
        Effect   = "Deny"
        Action   = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:RebootInstances",
          "ec2:Create*",
          "ec2:Delete*",
          "ec2:Modify*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Least-privilege group - S3 read-only
resource "aws_iam_group_policy_attachment" "leastperm_s3" {
  group      = aws_iam_group.leastperm_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Ineffective permission group - Deny EC2 StartInstances
resource "aws_iam_group_policy" "ineffective_policy" {
  name  = "IneffectivePolicy"
  group = aws_iam_group.ineffective_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ec2:StartInstances"
        Effect   = "Deny"
        Resource = "*"
      }
    ]
  })
}

# ----------------- IAM Users -----------------
locals {
  over_users  = ["OverUser1", "OverUser2"]
  least_users = ["LeastUser1", "LeastUser2"]
  ineff_users = ["IneffUser1", "IneffUser2"]
}

# Create all users
resource "aws_iam_user" "all_users" {
  for_each = toset(concat(local.over_users, local.least_users, local.ineff_users))
  name     = each.value
}

# ----------------- User Group Memberships -----------------
resource "aws_iam_user_group_membership" "over_users_membership" {
  for_each = toset(local.over_users)
  user     = aws_iam_user.all_users[each.value].name
  groups   = [aws_iam_group.overperm_group.name]
}

resource "aws_iam_user_group_membership" "least_users_membership" {
  for_each = toset(local.least_users)
  user     = aws_iam_user.all_users[each.value].name
  groups   = [aws_iam_group.leastperm_group.name]
}

resource "aws_iam_user_group_membership" "ineff_users_membership" {
  for_each = toset(local.ineff_users)
  user     = aws_iam_user.all_users[each.value].name
  groups   = [aws_iam_group.ineffective_group.name]
}

# ----------------- Access Keys -----------------
resource "aws_iam_access_key" "over_user1_key" {
  user = aws_iam_user.all_users["OverUser1"].name
}

resource "aws_iam_access_key" "least_user1_key" {
  user = aws_iam_user.all_users["LeastUser1"].name
}

resource "aws_iam_access_key" "ineff_user1_key" {
  user = aws_iam_user.all_users["IneffUser1"].name
}

# ----------------- AWS Resources -----------------
# 1️⃣ S3 Bucket
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "lab_bucket" {
  bucket = "iam-ape-lab-bucket-${random_id.suffix.hex}"
}

# 2️⃣ DynamoDB Table
resource "aws_dynamodb_table" "lab_table" {
  name         = "IAMAPE-Lab-Table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserID"

  attribute {
    name = "UserID"
    type = "S"
  }
}

# 3️⃣ EC2 Instance
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "lab_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  tags = {
    Name = "IAMAPE-Lab-EC2"
  }
}

# 4️⃣ Lambda Function
resource "aws_iam_role" "lambda_exec" {
  name = "IAMAPE-LambdaExecRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_lambda_function" "lab_function" {
  function_name = "IAMAPE-Lab-Lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  filename      = "lambda_function_payload.zip"
}

# 5️⃣ Secrets Manager Secret (randomized)
resource "random_string" "secret_name_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "random_string" "secret_value" {
  length  = 16
  upper   = true
  special = true
}

resource "aws_secretsmanager_secret" "lab_secret" {
  name = "iamape-secret-${random_string.secret_name_suffix.result}"
}

resource "aws_secretsmanager_secret_version" "lab_secret_value" {
  secret_id     = aws_secretsmanager_secret.lab_secret.id
  secret_string = random_string.secret_value.result
}

# ----------------- Outputs -----------------
output "all_users" {
  value = keys(aws_iam_user.all_users)
}

output "over_user1_access_key" {
  value = aws_iam_access_key.over_user1_key.id
}

output "least_user1_access_key" {
  value = aws_iam_access_key.least_user1_key.id
}

output "ineff_user1_access_key" {
  value = aws_iam_access_key.ineff_user1_key.id
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
