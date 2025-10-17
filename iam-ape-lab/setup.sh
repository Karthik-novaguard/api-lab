#!/bin/bash

# Bash script to install all necessary tools for the iam-ape lab on Ubuntu.

echo "🚀 Starting Tool Installation..."

# --- Step 1: Install System Dependencies ---
echo "📦 Installing required system packages (Python, AWS CLI, jq)..."
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y software-properties-common > /dev/null 2>&1
sudo add-apt-repository -y ppa:deadsnakes/ppa > /dev/null 2>&1
sudo apt-get install -y python3.9 python3-pip awscli jq > /dev/null 2>&1
echo "✅ System packages installed."

# --- Step 2: Install Terraform ---
echo "🔧 Installing Terraform..."
sudo apt-get install -y gpg
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y terraform > /dev/null 2>&1
echo "✅ Terraform installed."

# --- Step 3: Install and Update iam-ape ---
echo "🔧 Installing iam-ape..."
pip install iam-ape > /dev/null 2>&1
echo "✅ iam-ape is installed."

echo ""
echo "🎉 All tools are installed! You can now follow the instructions in the README file to run the lab."