# ------------------------
# IAM Users
# ------------------------
resource "aws_iam_user" "lab_users" {
  for_each = toset(var.lab_users)
  name     = each.value
}

# ------------------------
# IAM Policies
# ------------------------
resource "aws_iam_policy" "GoodPolicy" {
  name   = "GoodPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["s3:ListBucket", "s3:GetObject"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "OverPermPolicy" {
  name   = "OverPermPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["s3:*", "ec2:*", "iam:*"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "UnnecessaryPolicy" {
  name   = "UnnecessaryPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["dynamodb:DeleteTable", "sqs:DeleteQueue"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "DenyPolicy" {
  name   = "DenyPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["dynamodb:DeleteTable", "sqs:DeleteQueue"]
      Effect   = "Deny"
      Resource = "*"
    }]
  })
}

# ------------------------
# Attach Policies
# ------------------------
resource "aws_iam_user_policy_attachment" "attach_good" {
  user       = aws_iam_user.lab_users["LabUserGood"].name
  policy_arn = aws_iam_policy.GoodPolicy.arn
}

resource "aws_iam_user_policy_attachment" "attach_overperm" {
  user       = aws_iam_user.lab_users["LabUserOverPerm"].name
  policy_arn = aws_iam_policy.OverPermPolicy.arn
}

resource "aws_iam_user_policy_attachment" "attach_unnecessary" {
  user       = aws_iam_user.lab_users["LabUserUnnecessary"].name
  policy_arn = aws_iam_policy.UnnecessaryPolicy.arn
}

resource "aws_iam_user_policy_attachment" "attach_deny_to_unnecessary" {
  user       = aws_iam_user.lab_users["LabUserUnnecessary"].name
  policy_arn = aws_iam_policy.DenyPolicy.arn
}

# ------------------------
# Other Resources for Lab
# ------------------------
resource "aws_dynamodb_table" "LabTable" {
  name         = "LabTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ID"
  attribute {
    name = "ID"
    type = "S"
  }
}

resource "aws_sqs_queue" "LabQueue" {
  name = "LabQueue"
}