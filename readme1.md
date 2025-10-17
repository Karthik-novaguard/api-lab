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

Part 2: Manual Lab Execution
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
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile admin-ape --query "Account" --output text)
```

Now, run the analysis commands:


```bash
# Over-Privileged Users
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/OverUser1" -o overuser1_analysis.json -f verbose
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/OverUser2" -o overuser2_analysis.json -f verbose
```

```bash
# Least-Privilege Users
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/LeastUser1" -o leastuser1_analysis.json -f verbose
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/LeastUser2" -o leastuser2_analysis.json -f verbose
```

```bash
# Denied/Ineffective Users
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/IneffUser1" -o ineffuser1_analysis.json -f verbose
iam-ape --profile admin-ape --arn "arn:aws:iam::${AWS_ACCOUNT_ID}:user/IneffUser2" -o ineffuser2_analysis.json -f verbose
```

Step 5: Review the Results
List the generated JSON files and view their contents to see the analysis. or u can directly see on `.json` files

```bash
ls *_analysis.json
cat leastuser1_analysis.json
```

Part 3: Cleanup
When you are finished, run this command to delete all the IAM resources you created.

```bash
terraform destroy --auto-approve
```