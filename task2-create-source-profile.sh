#!/usr/bin/env bash
set -euo pipefail

# Task 2: Create the Amazon RDS for MySQL source connection profile.
# Run this in authenticated Google Cloud Shell.

command -v gcloud >/dev/null 2>&1 || {
  echo "gcloud is required. Run this script in Google Cloud Shell." >&2
  exit 1
}

if ! command -v dig >/dev/null 2>&1; then
  echo "Installing dig (dnsutils)..."
  sudo apt-get update
  sudo apt-get install -y dnsutils
fi

read -r -p "AWS RDS hostname: " RDS_HOSTNAME
if [[ -z "$RDS_HOSTNAME" ]]; then
  echo "RDS hostname is required." >&2
  exit 1
fi

RDS_IP="$(dig +short "$RDS_HOSTNAME" A | tail -n 1)"
if [[ ! "$RDS_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "Could not resolve an IPv4 address for $RDS_HOSTNAME" >&2
  exit 1
fi

echo "Resolved RDS address: $RDS_IP"
read -r -p "Database username [admin]: " DB_USERNAME
DB_USERNAME="${DB_USERNAME:-admin}"
read -r -s -p "Database password [press Enter for changeme]: " DB_PASSWORD
printf '\n'
DB_PASSWORD="${DB_PASSWORD:-changeme}"

PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
  echo "No Google Cloud project is configured." >&2
  exit 1
fi

# The lab's connection profile name is mysql-rds-source. The ID is explicit
# here because the CLI requires one; the Console may generate it automatically.
gcloud database-migration connection-profiles create mysql mysql-rds-source \
  --project="$PROJECT_ID" \
  --region=us-west1 \
  --host="$RDS_IP" \
  --port=3306 \
  --username="$DB_USERNAME" \
  --password="$DB_PASSWORD" \
  --display-name=mysql-rds-source \
  --no-async

echo "Task 2 source connection profile created: mysql-rds-source"
