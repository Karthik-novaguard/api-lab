variable "aws_region" {
  description = "The AWS region to deploy the lab resources in."
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "The AWS CLI profile to use for deployment."
  type        = string
  default     = "admin-ape"
}