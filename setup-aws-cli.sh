#!/usr/bin/env bash
set -euo pipefail

# Task 1: Install and configure the AWS CLI in Google Cloud Shell.
# Credentials are entered interactively and are intentionally not stored in this script.

if ! command -v aws >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y curl unzip

  workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' EXIT

  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o "$workdir/awscliv2.zip"
  unzip -q "$workdir/awscliv2.zip" -d "$workdir"
  sudo "$workdir/aws/install" --update
fi

echo "AWS CLI version:"
aws --version

echo
echo "Enter the lab-provided AWS credentials when prompted."
echo "Default region: us-east-1"
echo "Leave Default output format empty and press Enter."
aws configure

echo
echo "AWS CLI configuration completed."
aws configure get region
