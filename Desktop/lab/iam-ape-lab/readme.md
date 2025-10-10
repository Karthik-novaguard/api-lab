# Configure AWS CLI first:

```bash
aws configure
```
AWS Access Key ID

AWS Access Key ID [None]: <Enter your IAM Access Key>
AWS Secret Access Key [None]: <Enter your IAM Secret Key>
Default region name [None]: us-west-2
Default output format [None]: json

# Navigate to the folder:

```bash
cd iam-ape-lab/terraform
```

# Initialize Terraform:
```bash
terraform init
```

#  Apply the configuration:

```bash
terraform apply -auto-approve
```

# Copy the arn's and pase in the below commands

{
  "LabUserGood": "arn:aws:iam::893380949689:user/LabUserGood",
  "LabUserOverPerm": "arn:aws:iam::893380949689:user/LabUserOverPerm",
  "LabUserUnnecessary": "arn:aws:iam::893380949689:user/LabUserUnnecessary"
}

Exports Terraform outputs as JSON:

```bash
terraform output -json > terraform_output.json
```

# Replace <USER_ARN> with actual ARN from terraform_output.json

```bash
iam-ape --arn arn:aws:iam::<your-aws-account-id>:user/LabUserGood -p default -f verbose -o iam_ape_report_LabUserGood.json
```
```bash
iam-ape --arn arn:aws:iam::<your-aws-account-id>:user/LabUserOverPerm -p default -f verbose -o iam_ape_report_LabUserOverPerm.json
```

```bash
iam-ape --arn arn:aws:iam::<your-aws-account-id>:user/LabUserUnnecessary -p default -f verbose -o iam_ape_report_LabUserUnnecessary.json
```
# Example like this 

# iam-ape --arn arn:aws:iam::893380949689:user/LabUserGood -p default -f verbose -o iam_ape_report_LabUserGood.json
# iam-ape --arn arn:aws:iam::893380949689:user/LabUserOverPerm -p default -f verbose -o iam_ape_report_LabUserOverPerm.json
# iam-ape --arn arn:aws:iam::893380949689:user/LabUserUnnecessary -p default -f verbose -o iam_ape_report_LabUserUnnecessary.json
###
# Sample Output (Truncated):

[*] Running IAM-APE for arn:aws:iam::123456789012:user/LabUserTest ...
[*] IAM-APE analysis completed. Report saved as iam_ape_report_20251010_150500.json

#  Destroy terraform

```bash 
terraform destroy --auto-approve
```