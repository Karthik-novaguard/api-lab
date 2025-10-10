#!/usr/bin/env bash
set -e

echo "[*] Starting IAM-APE Lab Setup for Learners"

# Install system packages
sudo apt update && sudo apt install -y wget curl git unzip build-essential python3 python3-pip jq

# Install AWS CLI
if ! command -v aws &>/dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

# Install Terraform
if ! command -v terraform &>/dev/null; then
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update
    sudo apt install -y terraform
fi

# Install Python dependencies for IAM-APE (if any)
pip3 install --upgrade pip
pip3 install -r requirements.txt

echo "[*] Setup complete. Learners can now run IAM-APE manually."
