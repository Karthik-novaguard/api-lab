# Update package lists

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.9
sudo apt install awscli
```

Update packages → add support for PPAs → add Deadsnakes PPA → install Python 3.9.
You can then use this Python version to install packages like iam-ape in a virtual environment or system-wide.
First update the system package list, then install the AWS CLI so you can interact with AWS from the terminal.

# Change directory to iam-ape-lab/terraform

```bash
cd iam-ape-lab/terraform
```

# Configure aws

```bash
aws configure
```

AWS Access Key ID [None]: Paste the Access key ID you saved in Part 2 and press Enter.

AWS Secret Access Key [None]: Paste the Secret access key you saved and press Enter.

Default region name [None]: us-west-2

Default output format [None]: Press enter or use json

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

# Install pip 

```bash
pip install iam-ape
```

Installs IAM-APE so you can use it to analyze AWS IAM permissions.

# Update ape 

```bash
iam-ape --update
```

Keeps IAM-APE’s action list current so permission evaluation is accurate.

# List your usernames

```bash
aws iam list-users
```

This AWS CLI command lists all IAM users in your AWS account.

Copy the <arn> and paste in the below command 

# To fetch the whole account details

```bash
aws iam get-account-authorization-details
```

# Press "q" to exit from the terminal

It retrieves all IAM users, groups, roles, and their attached or inline policies from your AWS account in one detailed JSON output.

# Here we have 2 ways 
1. Live Fetch from AWS
2. Using a Local File (More Efficient)

# First Way
# Run the arn 

```bash
iam-ape --arn arn:aws:iam::<aws-accountid>:user/<username> --profile default
```

# example iam-ape --arn arn:aws:iam::<1234321543454>:user/<security-audit-user> --profile default

Analyze the effective IAM permissions of the specified user (<username>) in the given AWS account by fetching live data from AWS using the default AWS CLI profile.

# Second Way
# Get account authorization details

```bash
aws iam get-account-authorization-details > auth-details.json
```

This command exports all IAM users, groups, roles, and their policies from your AWS account into a file named auth-details.json for offline analysis.

# Save the output to a file

```bash
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserGood --output effective_policy.json --profile default
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserOverPerm --output effective_policy.json --profile default
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserUnnecessary --output effective_policy.json --profile default

```

# Use “clean” or “verbose” formats

# Clean format
```bash
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserGood --output result.json -f clean --profile default
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserOverPerm --output result.json -f clean --profile default
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserUnnecessary --output result.json -f clean --profile default
```

# Verbose output
```bash
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserGood --output result.json -f verbose --profile default
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserOverPerm --output result.json -f verbose --profile default
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserUnnecessary --output result.json -f verbose --profile default
```

# Point APE to this file:

```bash
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserGood --input auth-details.json
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserOverPerm --input auth-details.json
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserUnnecessary --input auth-details.json
```

# Offline analysis from a file

```bash
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserGood --output effective_policy.json
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserOverPerm --output effective_policy.json
iam-ape --arn arn:aws:iam::<aws-accountid>:user/LabUserUnnecessary --output effective_policy.json
```

Analyze the effective IAM permissions of the specified user (<username>) using the local file auth-details.json instead of fetching data live from AWS.

# Sample Output (Truncated):

[*] Running IAM-APE for arn:aws:iam::123456789012:user/LabUserTest ...
[*] IAM-APE analysis completed. Report saved as iam_ape_report_20251010_150500.json

#  Destroy terraform

```bash 
terraform destroy --auto-approve
```

