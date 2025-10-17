# Update package lists

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.9
sudo apt install awscli
sudo apt-get install jq
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

# Find the aws account number 

```bash
aws sts get-caller-identity --query "Account" --output text```
```

# Here we have 2 ways 
1. Live Fetch from AWS
2. Using a Local File (More Efficient)

**First Way**

# Run the arn 

## 2. iam-ape Commands
Replace <YOUR_AWS_ACCOUNT_ID> with the ID you just retrieved.

🧑‍💻 Over-Privileged Users
These users have AdministratorAccess, so iam-ape will show a vast number of allowed actions.

Bash

# Analyze OverUser1

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:user/OverUser1"
```

# Analyze OverUser2

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:user/OverUser2"
```

Expected Output: You will see a very long list under ✅ ALLOWED ACTIONS, likely showing */* (all actions on all resources). This demonstrates a classic over-permissioned identity.


✅ Least-Privilege Users
These users have only S3 read-only access. The output will be very specific and limited.

Bash

# Analyze LeastUser1

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:user/LeastUser1"
```

# Analyze LeastUser2

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:user/LeastUser2"

```

Expected Output: The ✅ ALLOWED ACTIONS section will only contain S3 read permissions (like s3:GetObject, s3:ListBucket). This is a perfect example of least privilege.

⚠️ Denied/Ineffective Users
These users have no Allow policies and one explicit Deny policy. This will show how Deny statements are evaluated.

Bash

# Analyze IneffUser1

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:user/IneffUser1"
```

# Analyze IneffUser2

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::<YOUR_AWS_ACCOUNT_ID>:user/IneffUser2"
```

Expected Output:

The ✅ ALLOWED ACTIONS section will be empty.

The ❌ DENIED ACTIONS section will explicitly list ec2:StartInstances. This clearly shows an identity that has no permissions and is explicitly blocked from performing a specific action.

**example for particular user**

# Analyze OverUser1

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/OverUser1"

# Analyze OverUser2
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/OverUser2"

# Analyze LeastUser1
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/LeastUser1"

# Analyze LeastUser2
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/LeastUser2"

# Analyze IneffUser1
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/IneffUser1"

# Analyze IneffUser2
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/IneffUser2"
```

**Second Way**

# Get account authorization details

```bash
aws iam get-account-authorization-details --profile admin-ape > auth-details.json
```
What this does:

aws iam get-account-authorization-details: The AWS CLI command to request the full IAM report.

--profile admin-ape: Uses the specific AWS credentials profile you've been using.

> auth-details.json: Redirects the output into a new file named auth-details.json in your current directory.

# Run iam-ape with the Local File 🚀

Now, use the --local-file flag to tell iam-ape to read from auth-details.json instead of fetching live data.

🧑‍💻 Over-Privileged Users

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::<Accountid>:user/OverUser1"
```

✅ Least-Privilege Users

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::<Accountid>:user/LeastUser1"
```

⚠️ Denied/Ineffective Users

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::<Accountid>:user/IneffUser1"
```

The output for each command will be identical to the live fetch, but the analysis will complete much faster because all the data is already on your machine.

**for particular user**

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::893380949689:user/OverUser1"
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::893380949689:user/LeastUser1"
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::893380949689:user/IneffUser1"
```

# Saving Each Output to a Separate File
Using > will overwrite the file if it already exists, or create it if it doesn't.

📝 Over-Privileged User Report

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::<Accountid>::user/OverUser1" > overuser1_report.txt
```

🧑‍💻 Over-Privileged User 2

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::<Accountid>:user/OverUser2" > overuser2_report.txt
```

📝 Least-Privilege User Report

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::<Accountid>::user/LeastUser1" > leastuser1_report.txt
```

✅ Least-Privilege User 2

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::<Accountid>::user/LeastUser2" > leastuser2_report.txt
```

📝 Denied/Ineffective User Report

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::<Accountid>::user/IneffUser1" > ineffuser1_report.txt
```

⚠️ Denied/Ineffective User 2

```bash 
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::<Accountid>::user/IneffUser2" > ineffuser2_report.txt
```

After running these, you will have three new text files in your directory, each containing the specific report.

## 3. List Policies from the User's Groups (Most Important)
This is a two-step process and is where you'll find the policies for your users.

Step A: Find out which groups the user belongs to.

```bash
aws iam list-groups-for-user --profile < This will be the account name> --user-name <username>
```

# example

```bash
aws iam list-groups-for-user --profile admin-ape --user-name OverUser1
```

Expected Output: This will show you that OverUser1 is a member of the GroupOverPerm group.

*JSON*
{
    "Groups": [
        {
            "Path": "/",
            "GroupName": "GroupOverPerm",
            "GroupId": "AGPAEXAMPLEGROUPID",
            "Arn": "arn:aws:iam::893380949689:group/GroupOverPerm",
            "CreateDate": "2025-10-17T12:00:00Z"
        }
    ]
}

Step B: List the policies attached to that group.
Now that you know the group name (GroupOverPerm), you can check its policies.

```bash
aws iam list-attached-group-policies --profile < This will be the account name > --group-name < Which group u want to check >
```

# Example

```bash
aws iam list-attached-group-policies --profile admin-ape --group-name GroupOverPerm
```

Expected Output: This will show the AdministratorAccess policy that grants all the permissions.

*JSON*
{
    "AttachedPolicies": [
        {
            "PolicyName": "AdministratorAccess",
            "PolicyArn": "arn:aws:iam::aws:policy/AdministratorAccess"
        }
    ]
}

# Create JSON Files for Each User
Run these commands. Each one will read your large auth-details.json, find the data for a specific user, and save just that data into a new, smaller JSON file.

Over-Privileged Users

```bash
jq '.UserDetailList[] | select(.UserName == "OverUser1")' auth-details.json > overuser1_policies.json
jq '.UserDetailList[] | select(.UserName == "OverUser2")' auth-details.json > overuser2_policies.json
```

Least-Privilege Users

```bash
jq '.UserDetailList[] | select(.UserName == "LeastUser1")' auth-details.json > leastuser1_policies.json
jq '.UserDetailList[] | select(.UserName == "LeastUser2")' auth-details.json > leastuser2_policies.json
```

Denied/Ineffective Users

```bash
jq '.UserDetailList[] | select(.UserName == "IneffUser1")' auth-details.json > ineffuser1_policies.json
jq '.UserDetailList[] | select(.UserName == "IneffUser2")' auth-details.json > ineffuser2_policies.json
```

## What's Inside the New JSON Files?
After running these commands, you will have new files like overuser1_policies.json. This file will not contain the iam-ape analysis (Allowed/Denied actions). Instead, it will contain a structured JSON object with all the raw IAM data for that user, including:

User details (ARN, UserID, CreateDate).

A list of groups they belong to.

Managed policies attached to them.

Inline policies embedded in their profile.

This gives you a clean, machine-readable file for each user's raw permissions. 

# Run the Commands to Generate JSON Files if u want to see the actions  

Now, you can use the pipe character (|) to send the output of iam-ape directly into our new Python script, and then redirect that script's output into your JSON file.

# Over-Privileged Users

```bash 
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::893380949689:user/OverUser1" 2>&1 | python3 parse_iam_ape.py > overuser1_analysis.json
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::893380949689:user/OverUser2" 2>&1 | python3 parse_iam_ape.py > overuser2_analysis.json
```

# Least-Privilege Users

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::893380949689:user/LeastUser1" 2>&1 | python3 parse_iam_ape.py > leastuser1_analysis.json
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::893380949689:user/LeastUser2" 2>&1 | python3 parse_iam_ape.py > leastuser2_analysis.json
```

# Denied/Ineffective Users

```bash
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::893380949689:user/IneffUser1" 2>&1 | python3 parse_iam_ape.py > ineffuser1_analysis.json
iam-ape --profile admin-ape -i auth-details.json --arn "arn:aws:iam::893380949689:user/IneffUser2" 2>&1 | python3 parse_iam_ape.py > ineffuser2_analysis.json
```

# This command analyzes a user and saves the results directly to a JSON file.

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/LeastUser1" -o leastuser1_analysis.json -f verbose
```

Simple Explanation for Learners 🎓
You can break this command down into three easy parts:

The "Who": iam-ape --profile admin-ape --arn "..."

This is the basic part. It just tells iam-ape who you want to analyze.

The "Where": -o leastuser1_analysis.json

This tells iam-ape where to save the report. The -o flag is short for output.

The "How": -f verbose

This is the magic part. It tells iam-ape how to format the report. The verbose format is the one that creates a detailed JSON file. Think of -f as being for format.

By combining these three parts, you get a single, clean command that runs the analysis and gives you the JSON file you need.

**Commands for Your Lab Users**

# Over-Privileged User

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/OverUser1" -o overuser1_analysis.json -f verbose
```

# Over-Privileged User 2

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/OverUser2" -o overuser2_analysis.json -f verbose
```

# Least-Privilege User

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/LeastUser1" -o leastuser1_analysis.json -f verbose
```

# Least-Privilege User 2

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/LeastUser2" -o leastuser2_analysis.json -f verbose
```
# Denied/Ineffective User 2

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/IneffUser2" -o ineffuser2_analysis.json -f verbose
```

# Denied/Ineffective User

```bash 
iam-ape --profile admin-ape --arn "arn:aws:iam::893380949689:user/IneffUser1" -o ineffuser1_analysis.json -f verbose
```

#  Destroy terraform

```bash 
terraform destroy --auto-approve
```

