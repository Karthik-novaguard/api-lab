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
  profile = "admin-ape" # can be changed per user
}

# ----------------- Unique Lab Suffix -----------------
resource "random_string" "lab_suffix" {
  length  = 6
  special = false
  upper   = false
  lower   = true
}

# ----------------- IAM Groups -----------------
resource "aws_iam_group" "overperm_group" {
  name = "GroupOverPerm-${random_string.lab_suffix.result}"
}

resource "aws_iam_group" "leastperm_group" {
  name = "GroupLeastPerm-${random_string.lab_suffix.result}"
}

resource "aws_iam_group" "ineffective_group" {
  name = "GroupIneffectivePerm-${random_string.lab_suffix.result}"
}

# ----------------- IAM Policies -----------------
resource "aws_iam_group_policy" "overperm_custom" {
  name  = "OverPermCustomPolicy-${random_string.lab_suffix.result}"
  group = aws_iam_group.overperm_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:ListAllMyBuckets","s3:ListBucket","s3:GetBucketLocation","s3:GetObject"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["ec2:Describe*"]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = ["s3:DeleteObject","s3:DeleteObjectVersion","s3:DeleteBucket"]
        Resource = ["arn:aws:s3:::*","arn:aws:s3:::*/*"]
      },
      {
        Effect = "Deny"
        Action = ["ec2:RunInstances","ec2:TerminateInstances","ec2:StopInstances","ec2:StartInstances","ec2:RebootInstances","ec2:Create*","ec2:Delete*","ec2:Modify*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "leastperm_s3" {
  group      = aws_iam_group.leastperm_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_group_policy" "ineffective_policy" {
  name  = "IneffectivePolicy-${random_string.lab_suffix.result}"
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

# ----------------- Users Map -----------------
locals {
  all_users_map = {
    OverUser1  = "over"
    OverUser2  = "over"
    LeastUser1 = "least"
    LeastUser2 = "least"
    IneffUser1 = "ineff"
    IneffUser2 = "ineff"
  }
}

# ----------------- Random suffix per user -----------------
resource "random_string" "user_suffix" {
  for_each = local.all_users_map
  length   = 6
  upper    = true
  special  = false
}

# ----------------- IAM Users -----------------
resource "aws_iam_user" "all_users" {
  for_each = local.all_users_map
  name     = "${each.key}-${random_string.user_suffix[each.key].result}"
}

# ----------------- User Group Memberships -----------------
resource "aws_iam_user_group_membership" "over_users_membership" {
  for_each = { for k,v in local.all_users_map : k => aws_iam_user.all_users[k].name if v == "over" }
  user     = each.value
  groups   = [aws_iam_group.overperm_group.name]
}

resource "aws_iam_user_group_membership" "least_users_membership" {
  for_each = { for k,v in local.all_users_map : k => aws_iam_user.all_users[k].name if v == "least" }
  user     = each.value
  groups   = [aws_iam_group.leastperm_group.name]
}

resource "aws_iam_user_group_membership" "ineff_users_membership" {
  for_each = { for k,v in local.all_users_map : k => aws_iam_user.all_users[k].name if v == "ineff" }
  user     = each.value
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
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "lab_bucket" {
  bucket = "iam-ape-lab-bucket-${random_id.bucket_suffix.hex}"
}

resource "aws_dynamodb_table" "lab_table" {
  name         = "IAMAPE-Lab-Table-${random_string.lab_suffix.result}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "UserID"

  attribute {
    name = "UserID"
    type = "S"
  }
}

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
    Name = "IAMAPE-Lab-EC2-${random_string.lab_suffix.result}"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "IAMAPE-LambdaExecRole-${random_string.lab_suffix.result}"

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
  function_name = "IAMAPE-Lab-Lambda-${random_string.lab_suffix.result}"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  filename      = "lambda_function_payload.zip"
}

resource "random_string" "secret_value" {
  length  = 16
  upper   = true
  special = true
}

resource "aws_secretsmanager_secret" "lab_secret" {
  name = "iamape-secret-${random_string.lab_suffix.result}"
}

resource "aws_secretsmanager_secret_version" "lab_secret_value" {
  secret_id     = aws_secretsmanager_secret.lab_secret.id
  secret_string = random_string.secret_value.result
}

# ----------------- Outputs -----------------
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
