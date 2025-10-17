**AWS IAM Permissions Lab with Terraform & IAM-APE**
*Lab Overview*
In this lab, we create AWS resources with Terraform and then analyze IAM user permissions using IAM-APE. This lets us see which users are overprivileged, have least privilege, or are denied certain actions. We can check permissions in clean or verbose formats, using either live AWS data or a local export file.
You will learn how to:

Identify overprivileged, least-privilege, denied, and ineffective IAM users.

Fetch IAM user policies live from AWS or use a local JSON export.

Generate clean or verbose JSON reports for offline analysis.

Prerequisites:

Ubuntu/Debian system or WSL

Python 3.9+

AWS CLI installed and configured

Terraform installed

Access to an AWS account with IAM privileges
1. System Setup
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

2. Change Directory to Terraform Project

```bash
cd iam-ape-lab/terraform
```

3. Configure AWS CLI

```bash
aws configure
```

AWS Access Key ID [None]: Paste the Access key ID you saved in Part 2 and press Enter.

AWS Secret Access Key [None]: Paste the Secret access key you saved and press Enter.

Default region name [None]: us-west-2

Default output format [None]: Press enter or use json

4. Initialize & Apply Terraform

```bash
terraform init
```

#  Apply the configuration:

```bash
terraform apply -auto-approve
```
Export Terraform Outputs

```bash
terraform output -json > terraform_output.json
```

# Copy the arn's and pase in the below commands

This creates a JSON file with ARNs of IAM users:
{
  "user-overprivileged": "arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-overprivileged",
  "user-least-privilege": "arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-least-privilege",
  "user-denied": "arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-denied",
  "user-ineffective": "arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-ineffective"
}

5. Install IAM-APE

```bash
pip install iam-ape
```

Installs IAM-APE so you can use it to analyze AWS IAM permissions.

# Update ape 

```bash
iam-ape --update
```

Keeps IAM-APE’s action list current so permission evaluation is accurate.

6. List IAM Users

```bash
aws iam list-users
```

Copy the ARN of a user to use in IAM-APE commands.

7. Analyze IAM Users

There are two ways to analyze IAM permissions:
7.1 Live Fetch from AWS2.
7.2 Using a Local File (More Efficient)

**First Way**

# Run the arn 

```bash
iam-ape --arn arn:aws:iam::<aws-accountid>:user/<username> --profile default
```

it evaluates and reports what actions the given IAM user can actually perform in your AWS account.

**example commands for particular user**

```bash
iam-ape --arn arn:aws:iam::893380949689:user/Novaguard@1 --profile default

iam-ape --arn arn:aws:iam::893380949689:user/user-least-privilege --profile default

iam-ape --arn arn:aws:iam::893380949689:user/user-denied --profile default

iam-ape --arn arn:aws:iam::893380949689:user/user-ineffective --profile default
```

**Second Way**

# Get account authorization details

```bash
aws iam get-account-authorization-details > aws-details.json
```

This command exports all IAM users, groups, roles, and their policies from your AWS account into a file named auth-details.json for offline analysis.

# Save the output to a file

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-overprivileged --output user-overprivileged_policy.json --profile default
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-least-privilege --output user-least-privilege_policy.json --profile default
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-denied --output user-denied_policy.json --profile default
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-ineffective --output user-ineffective_policy.json --profile default
```

They analyze a specified IAM user’s permissions in AWS and save the effective permissions report to a JSON file.

**example commands for every user where they can move the policies into .json file**

```bash
iam-ape --arn arn:aws:iam::893380949689:user/user-overprivileged --output user-overprivileged_policy.json --profile default

iam-ape --arn arn:aws:iam::893380949689:user/user-least-privilege --output user-least-privilege_policy.json --profile default

iam-ape --arn arn:aws:iam::893380949689:user/user-denied --output user-denied_policy.json --profile default

iam-ape --arn arn:aws:iam::893380949689:user/user-ineffective --output user-ineffective_policy.json --profile default
```

# Use “clean” or “verbose” formats

*Clean format*

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-overprivileged --output user-overprivileged_result.json -f clean --profile default
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-least-privilege --output user-least-privilege_result.json -f clean --profile default
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-denied --output user-denied_result.json -f clean --profile default
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-ineffective --output user-ineffective_result.json -f clean --profile default
```

Evaluate each IAM user’s permissions and output a simplified/clean JSON report for offline review.

**example commands for every user where they can move the policies into .json file**

```bash
iam-ape --arn arn:aws:iam::893380949689:user/user-overprivileged --output user-overprivileged_result.json -f clean --profile default

iam-ape --arn arn:aws:iam::893380949689:user/user-least-privilege --output user-least-privilege_result.json -f clean --profile default

iam-ape --arn arn:aws:iam::893380949689:user/user-denied --output user-denied_result.json -f clean --profile default

iam-ape --arn arn:aws:iam::893380949689:user/user-ineffective --output user-ineffective_result.json -f clean --profile default
```

*Verbose format*

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-overprivileged --input auth-details.json --output user-overprivileged_result.json -f verbose
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-least-privilege --input auth-details.json --output user-least-privilege_result.json -f verbose
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-denied --input auth-details.json --output user-denied_result.json -f verbose
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-ineffective --input auth-details.json --output user-ineffective_result.json -f verbose
```

Evaluate each IAM user’s permissions from a local account export and generate a detailed verbose JSON report for offline analysis

**example commands for every user where they can move the policies into .json file**

```bash
iam-ape --arn arn:aws:iam::893380949689:user/user-overprivileged --input auth-details.json --output user-overprivileged_result.json -f verbose

iam-ape --arn arn:aws:iam::893380949689:user/user-least-privilege --input auth-details.json --output user-least-privilege_result.json -f verbose

iam-ape --arn arn:aws:iam::893380949689:user/user-denied --input auth-details.json --output user-denied_result.json -f verbose

iam-ape --arn arn:aws:iam::893380949689:user/user-ineffective --input auth-details.json --output user-ineffective_result.json -f verbose
```

# Point APE to this file:

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-overprivileged --input auth-details.json --output user-overprivileged_result.json
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-least-privilege --input auth-details.json --output user-least-privilege_result.json
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-denied --input auth-details.json --output user-denied_result.json
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-ineffective --input auth-details.json --output user-ineffective_result.json
```

Here’s what each part does:

--arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/<username> → Specifies which IAM user you want to analyze.

--input auth-details.json → Uses the JSON file exported from AWS (aws iam get-account-authorization-details) to get all policy information for the account.

--output <file>.json → Saves the results to a separate file for each user. This prevents overwriting results.

Without -f verbose, the output is in default summary format, not a detailed verbose view.

**example commands for every user where they can move the policies into .json file**

```bash
iam-ape --arn arn:aws:iam::893380949689:user/user-overprivileged --input auth-details.json --output user-overprivileged_result.json

iam-ape --arn arn:aws:iam::893380949689:user/user-least-privilege --input auth-details.json --output user-least-privilege_result.json

iam-ape --arn arn:aws:iam::893380949689:user/user-denied --input auth-details.json --output user-denied_result.json

iam-ape --arn arn:aws:iam::893380949689:user/user-ineffective --input auth-details.json --output user-ineffective_result.json
```

# Offline analysis from a file

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-overprivileged --output user-overprivileged_result.json
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-least-privilege --output user-least-privilege_result.json
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-denied --output user-denied_result.json
```

```bash
iam-ape --arn arn:aws:iam::<AWS_ACCOUNT_ID>:user/user-ineffective --output user-ineffective_result.json
```

Fetch and evaluate each IAM user’s effective permissions directly from AWS and save the results to JSON files.

**example commands for every user where they can analyze the policies from .json file**

```bash
iam-ape --arn arn:aws:iam::893380949689:user/user-overprivileged --output user-overprivileged_result.json

iam-ape --arn arn:aws:iam::893380949689:user/user-least-privilege --output user-least-privilege_result.json

iam-ape --arn arn:aws:iam::893380949689:user/user-denied --output user-denied_result.json

iam-ape --arn arn:aws:iam::893380949689:user/user-ineffective --output user-ineffective_result.json
```

Analyze the effective IAM permissions of the specified user (<username>) using the local file auth-details.json instead of fetching data live from AWS.

# Sample Output (Truncated):

[*] Running IAM-APE for arn:aws:iam::123456789012:user/LabUserTest ...
[*] IAM-APE analysis completed. Report saved as iam_ape_report_20251010_150500.json

#  Destroy terraform

```bash 
terraform destroy --auto-approve
```

