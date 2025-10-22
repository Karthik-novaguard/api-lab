# AWS IAM-APE Analysis Lab 🔬

Welcome! This lab guides you through analyzing AWS IAM permissions using the `iam-ape` tool. You will first run a setup script to install all the necessary tools, and then you will run the lab commands manually.

## **Objective**
To deploy a set of IAM users with varying permission levels using Terraform and then use `iam-ape` to generate detailed JSON analysis reports for each user.

## **Prerequisites**
Before you begin, you will need:
* An AWS **Access Key ID**.
* An AWS **Secret Access Key**.

---
## **Part 1: Automated Tool Setup**

First, make the setup script executable and run it. This will install Terraform, AWS CLI, `iam-ape`, and other required tools.
```bash
chmod +x setup.sh
./setup.sh
```

Wait for the script to finish. Once it's done, proceed to Part 2.

Of course. Here is the complete README.md file based on the text you provided, ready for you to copy and paste.

Markdown

# AWS IAM-APE Analysis Lab 🔬

Welcome! This lab guides you through analyzing AWS IAM permissions using the `iam-ape` tool. You will first run a setup script to install all the necessary tools, and then you will run the lab commands manually.

## **Objective**
To deploy a set of IAM users with varying permission levels using Terraform and then use `iam-ape` to generate detailed JSON analysis reports for each user.

## **Prerequisites**
Before you begin, you will need:
* An AWS **Access Key ID**.
* An AWS **Secret Access Key**.

---
## **Part 1: Automated Tool Setup**

First, make the setup script executable and run it. This will install Terraform, AWS CLI, `iam-ape`, and other required tools.
```bash
chmod +x setup.sh
./setup.sh
```
Wait for the script to finish. Once it's done, proceed to Part 2.

**Part 2: Manual Lab Execution**
Now that the tools are installed, you will run the commands for the lab yourself.

Step 1: Configure AWS Credentials
Configure the AWS CLI with your credentials. You will be prompted to enter your keys.

```bash
aws configure --profile admin-ape
```
# Example

aws configure --profile admin-ape


AWS Access Key ID: [PASTE YOUR KEY HERE]

AWS Secret Access Key: [PASTE YOUR SECRET KEY HERE]

Default region name: us-west-2

Default output format: json

Step 2: Deploy AWS Resources
Navigate to the directory containing your Terraform files and deploy the IAM resources.
```bash
cd terraform
```

```bash
terraform init
```

```bash
terraform apply --auto-approve
```

Step 3: Update iam-ape Database
Fetch the latest list of AWS IAM actions to ensure your analysis is accurate.

```bash
iam-ape --update
```

Step 4: Analyze IAM Policies
Run the iam-ape command for each user to generate a detailed JSON analysis file.

First, get your AWS Account ID:

```bash
aws sts get-caller-identity --profile admin-ape --query "Account" --output text
```

Export account_id

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile admin-ape --query "Account" --output text)   
echo $AWS_ACCOUNT_ID    
```

List iam users

```bash
aws iam list-users
```

# Step 1: Get the Keys for a User

```bash
terraform output -json over_user1_access_keys
```
You will get an output like this. Copy the values.

```bash
{
  "access_key_id": "AKIAIOSFODNN7EXAMPLE",
  "secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
}
```

Step 2: Configure Your Terminal
Now, set the environment variables in your terminal.

# For Macos

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

# for windows

```bash
$env:AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

# Step 3: 🔬 Test the Permissions!
Now, your terminal is acting as OverUser1. You can test the policies you wrote.

# Test 1: OverUser1 (Overly Permissive)

This user has read access to S3/EC2 but is denied destructive actions. 

```bash
aws s3 ls
aws ec2 describe-instances
```

press q for quit from the inside terminal 

```bash
q 
```

This should FAIL (Deny):

```bash
aws ec2 terminate-instances --instance-ids $(terraform output -json resources_summary | jq -r .ec2)
aws s3 rm s3://$(terraform output -json resources_summary | jq -r .s3_bucket)/test.txt
```

These commands attempt to terminate the lab EC2 instance and delete a test file from the S3 bucket using Terraform outputs. They are used to test IAM permissions in practice—users with restrictive policies will see “Access Denied,” while users with appropriate permissions will succeed.

Sample output

```bash
terraform % aws s3 rm s3://$(terraform output -json resources_summary | jq -r .s3_bucket)/test.txt
delete failed: s3://iam-ape-lab-bucket-ee886fee/test.txt An error occurred (AccessDenied) when calling the DeleteObject operation: User: arn:aws:iam::893380949689:user/OverUser1-UkGLAB is not authorized to perform: s3:DeleteObject on resource: "arn:aws:s3:::iam-ape-lab-bucket-ee886fee/test.txt" with an explicit deny in an identity-based policy
```

# Test 2: LeastUser1 (Least Privilege)
This user only has S3 Read-Only access.

First, "log in" as this user (repeat Steps 1 and 2 with least_user1_access_keys).

Now, run the analysis commands:

This should WORK (Allow):

```bash
aws s3 ls
```

This should FAIL (Implicit Deny):

```bash
aws ec2 describe-instances
aws dynamodb list-tables
```

These commands demonstrate **read-only access**: users with only Describe/List permissions can run them successfully, while users without the required permissions will see **Access Denied**.

# Test 3: IneffUser1 (Ineffective)
This user is in a group with two policies:

An Allow for ec2:StartInstances,

A Deny for ec2:StartInstances.

This is the main test. The user has both Allow and Deny. The Deny will win.
```bash
# 1. First, get the ID of the EC2 instance
terraform output -json resources_summaryaws ec2 
#(Look at the output and copy the ec2 value, which looks like i-0123...)
aws ec2 start-instances --instance-ids "<EC2-id>"
```

Expected Result: ❗️ FAIL You will get an AccessDenied error. This proves that the explicit Deny policy overrode the Allow policy, making the Allow ineffective.

# Get the details using iam-ape

# Over-Privileged Users

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/<user-name>" -o overuser1_analysis.json -f verbose
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/<user-name>" -o overuser2_analysis.json -f verbose
```

# Least-Privilege Users

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/<user-name>" -o leastuser1_analysis.json -f verbose
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/<user-name>" -o leastuser2_analysis.json -f verbose
```

# Denied/Ineffective Users

```bash
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/<user-name>" -o ineffuser1_analysis.json -f verbose
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/<user-name>" -o ineffuser2_analysis.json -f verbose
```

Step 5: Review the Results
List the generated JSON files and view their contents to see the analysis. or u can directly see on `.json` files

```bash
ls *_analysis.json
cat leastuser1_analysis.json
```

**Part 3: Cleanup**

When you are finished, run this command to delete all the IAM resources you created.

```bash
unset 
AWS_ACCESS_KEY_ID 
AWS_SECRET_ACCESS_KEY 
AWS_DEFAULT_REGION
```

# Destroy resources

```bash
terraform destroy --auto-approve
```


