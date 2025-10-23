# ----------------- Unique Lab Suffix -----------------
resource "random_string" "lab_suffix" {
  length  = 6
  special = false
  upper   = false
  lower   = true
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
# 1. Overly Permissive Policy
resource "aws_iam_group_policy" "overperm_custom" {
  name  = "OverPermCustomPolicy-${random_string.lab_suffix.result}"
  group = aws_iam_group.overperm_group.name

  # --- THIS IS THE FIX ---
  # Wait for these resources to be created before building the policy
  depends_on = [
    aws_dynamodb_table.lab_table,
    aws_secretsmanager_secret.lab_secret
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // 1. S3 Allow (Overly permissive)
      {
        Effect   = "Allow"
        Action   = ["s3:ListAllMyBuckets", "s3:ListBucket", "s3:GetBucketLocation", "s3:GetObject"]
        Resource = "*"
      },
      // 2. EC2 Allow (Overly permissive)
      {
        Effect   = "Allow"
        Action   = ["ec2:Describe*"]
        Resource = "*"
      },
      // 3. S3 Deny
      {
        Effect = "Deny"
        Action = ["s3:DeleteObject", "s3:DeleteObjectVersion", "s3:DeleteBucket"]
        Resource = ["arn:aws:s3:::*", "arn:aws:s3:::*/*"]
      },
      // 4. EC2 Deny
      {
        Effect = "Deny"
        Action = ["ec2:RunInstances", "ec2:TerminateInstances", "ec2:StopInstances", "ec2:StartInstances", "ec2:RebootInstances", "ec2:Create*", "ec2:Delete*", "ec2:Modify*"]
        Resource = "*"
      },
      // 5. VALID NotAction Example (Overly permissive)
      {
        Effect    = "Allow"
        NotAction = "dynamodb:DeleteTable"
        Resource  = aws_dynamodb_table.lab_table.arn
      },
      // 6. VALID NotResource Example (Overly permissive)
      {
        Effect      = "Allow"
        Action      = "secretsmanager:GetSecretValue"
        NotResource = [aws_secretsmanager_secret.lab_secret.arn]
      }
    ]
  })
}

# 2. Least Privilege Policy
resource "aws_iam_group_policy" "leastperm_custom" {
  name  = "LeastPermCustomPolicy-${random_string.lab_suffix.result}"
  group = aws_iam_group.leastperm_group.name

  # --- THIS IS THE FIX ---
  # Wait for the S3 bucket to be created first
  depends_on = [
    aws_s3_bucket.lab_bucket
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      // Allows listing the bucket contents
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.lab_bucket.arn
      },
      // Allows all "Get" actions
      {
        Effect   = "Allow"
        Action   = "s3:Get*"
        Resource = "${aws_s3_bucket.lab_bucket.arn}/*"
      },
      // DENIES getting the ACL (the exception)
      {
        Effect   = "Deny"
        Action   = "s3:GetObjectAcl"
        Resource = "${aws_s3_bucket.lab_bucket.arn}/*"
      }
    ]
  })
}

# 3. Ineffective Policy
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
  for_each = { for k, v in local.all_users_map : k => aws_iam_user.all_users[k].name if v == "over" }
  user     = each.value
  groups   = [aws_iam_group.overperm_group.name]
}

resource "aws_iam_user_group_membership" "least_users_membership" {
  for_each = { for k, v in local.all_users_map : k => aws_iam_user.all_users[k].name if v == "least" }
  user     = each.value
  groups   = [aws_iam_group.leastperm_group.name]
}

resource "aws_iam_user_group_membership" "ineff_users_membership" {
  for_each = { for k, v in local.all_users_map : k => aws_iam_user.all_users[k].name if v == "ineff" }
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
  filename      = "lambda_function_payload.zip" # Make sure this file exists
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