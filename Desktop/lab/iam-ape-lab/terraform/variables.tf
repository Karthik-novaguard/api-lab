
variable "lab_users" {
  description = "A list of IAM user names for the lab."
  type        = list(string)
  default = [
    "LabUserGood",
    "LabUserOverPerm",
    "LabUserUnnecessary"
  ]
}