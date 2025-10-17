terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
# Over-permissioned users
resource "aws_iam_user_group_membership" "over_users_membership" {
  for_each = toset(local.over_users)
  user     = aws_iam_user.all_users[each.value].name
  groups   = [aws_iam_group.overperm_group.name]
}

# Least-permission users
resource "aws_iam_user_group_membership" "least_users_membership" {
  for_each = toset(local.least_users)
  user     = aws_iam_user.all_users[each.value].name
  groups   = [aws_iam_group.leastperm_group.name]
}

# Ineffective permission users
resource "aws_iam_user_group_membership" "ineff_users_membership" {
  for_each = toset(local.ineff_users)
  user     = aws_iam_user.all_users[each.value].name
  groups   = [aws_iam_group.ineffective_group.name]
}

# ----------------- Access Keys (one per first user in each group) -----------------
resource "aws_iam_access_key" "over_user1_key" {
  user = aws_iam_user.all_users["OverUser1"].name
}

resource "aws_iam_access_key" "least_user1_key" {
  user = aws_iam_user.all_users["LeastUser1"].name
}

resource "aws_iam_access_key" "ineff_user1_key" {
  user = aws_iam_user.all_users["IneffUser1"].name
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
