terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# --- DATA SOURCES ---

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# --- CORE RESOURCES ---

resource "aws_s3_bucket" "project_alpha_data" {
  bucket = "project-alpha-data-${random_id.bucket_suffix.hex}"
}

resource "aws_dynamodb_table" "project_alpha_config" {
  name           = "project-alpha-config"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "ID"

  attribute {
    name = "ID"
    type = "S"
  }
}

# --- SECRETS MANAGER ---

resource "aws_secretsmanager_secret" "alpha_db_credentials" {
  name        = "alpha-db-credentials-new"
  description = "Credentials for Project Alpha DB"
}

resource "aws_secretsmanager_secret_version" "alpha_db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.alpha_db_credentials.id
  secret_string = jsonencode({
    username = "admin",
    password = "fakePassword123"
  })
}

# --- EC2 INSTANCE ---

resource "aws_instance" "project_alpha_vm" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  tags = {
    Name    = "ProjectAlphaVM"
    Project = "Alpha"
  }
}

# --- LAMBDA FUNCTION ---

data "archive_file" "lambda_zip" {
  type                    = "zip"
  source_content          = "exports.handler = async (event) => { console.log('Hello from dummy Lambda!'); };"
  source_content_filename = "index.js"
  output_path             = "function.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role-for-alpha"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_function" "process_alpha_data" {
  function_name    = "process-alpha-data"
  filename         = data.archive_file.lambda_zip.output_path
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# --- IAM POLICIES ---

resource "aws_iam_policy" "general_admins_policy" {
  name        = "GeneralAdminsPolicy"
  description = "Grants sweeping admin access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:*", "dynamodb:*", "ec2:*", "lambda:*"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "app_operator_policy" {
  name        = "AppOperatorPolicy"
  description = "Least privilege policy for app operators"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ec2:StartInstances", "ec2:StopInstances"],
        Resource = "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
        Condition = {
          StringEquals = { "aws:ResourceTag/Project" = "Alpha" }
        }
      },
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = aws_lambda_function.process_alpha_data.arn
      },
      {
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = aws_secretsmanager_secret.alpha_db_credentials.arn
      }
    ]
  })
}

resource "aws_iam_policy" "data_science_policy" {
  name        = "DataSciencePolicy"
  description = "Broad permissions for data scientists"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:GetObject", "s3:PutObject", "ec2:DescribeInstances", "ec2:RunInstances"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "ci_cd_services_policy" {
  name        = "CiCdServicesPolicy"
  description = "Permissions for automation roles"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:PutObject", "lambda:UpdateFunctionCode", "iam:PassRole"],
      Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "alpha_project_boundary" {
  name        = "AlphaProjectBoundary"
  description = "Permissions boundary for Project Alpha"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:*", "lambda:*"],
      Resource = "*"
    }]
  })
}

# --- IAM GROUPS AND ATTACHMENTS ---

resource "aws_iam_group" "general_admins_group" { name = "General-Admins-Group" }
resource "aws_iam_group_policy_attachment" "ga_attach" {
  group      = aws_iam_group.general_admins_group.name
  policy_arn = aws_iam_policy.general_admins_policy.arn
}

resource "aws_iam_group" "app_operator_group" { name = "App-Operator-Group" }
resource "aws_iam_group_policy_attachment" "ao_attach" {
  group      = aws_iam_group.app_operator_group.name
  policy_arn = aws_iam_policy.app_operator_policy.arn
}

resource "aws_iam_group" "data_science_group" { name = "Data-Science-Group" }
resource "aws_iam_group_policy_attachment" "ds_attach" {
  group      = aws_iam_group.data_science_group.name
  policy_arn = aws_iam_policy.data_science_policy.arn
}

resource "aws_iam_group" "ci_cd_services_group" { name = "CI-CD-Services-Group" }
resource "aws_iam_group_policy_attachment" "cicd_attach" {
  group      = aws_iam_group.ci_cd_services_group.name
  policy_arn = aws_iam_policy.ci_cd_services_policy.arn
}

# --- IAM USERS AND MEMBERSHIPS ---

resource "aws_iam_user" "user_overprivileged" { name = "user-overprivileged" }
resource "aws_iam_user" "user_least_privilege" { name = "user-least-privilege" }
resource "aws_iam_user" "user_denied" { name = "user-denied" }

resource "aws_iam_user" "user_ineffective" {
  name                 = "user-ineffective"
  permissions_boundary = aws_iam_policy.alpha_project_boundary.arn
}

resource "aws_iam_user_group_membership" "memberships" {
  user   = aws_iam_user.user_overprivileged.name
  groups = [aws_iam_group.general_admins_group.name]
}
resource "aws_iam_user_group_membership" "memberships2" {
  user   = aws_iam_user.user_least_privilege.name
  groups = [aws_iam_group.app_operator_group.name]
}
resource "aws_iam_user_group_membership" "memberships3" {
  user   = aws_iam_user.user_denied.name
  groups = [aws_iam_group.data_science_group.name]
}
resource "aws_iam_user_group_membership" "memberships4" {
  user   = aws_iam_user.user_ineffective.name
  groups = [aws_iam_group.ci_cd_services_group.name]
}

# --- SPECIAL USER ATTACHMENTS ---

resource "aws_iam_user_policy" "user_denied_inline_policy" {
  name   = "DenySpecificActions"
  user   = aws_iam_user.user_denied.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Deny",
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.project_alpha_data.arn}/production/*"
      },
      {
        Effect   = "Deny",
        Action   = "ec2:RunInstances",
        Resource = "*",
        Condition = {
          StringEquals = { "ec2:InstanceType" = "m5.24xlarge" }
        }
      }
    ]
  })
}

# --- OUTPUTS ---

output "project_alpha_s3_bucket_name" {
  description = "The unique name of the S3 bucket created for Project Alpha."
  value       = aws_s3_bucket.project_alpha_data.id
}

output "project_alpha_ec2_instance_id" {
  description = "The ID of the EC2 instance for Project Alpha."
  value       = aws_instance.project_alpha_vm.id
}

output "project_alpha_ec2_instance_public_ip" {
  description = "The public IP address of the EC2 instance for Project Alpha."
  value       = aws_instance.project_alpha_vm.public_ip
}

output "lambda_function_arn" {
  description = "The ARN of the process-alpha-data Lambda function."
  value       = aws_lambda_function.process_alpha_data.arn
}
