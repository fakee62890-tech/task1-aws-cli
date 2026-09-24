#!/usr/bin/env bash
set -euo pipefail

# Task 2: Prepare and create the one-time RDS-to-Cloud-SQL migration job.
# The source profile is created by CLI. Destination selection and IP allowlist
# generation remain in the Google Cloud DMS wizard because the wizard generates
# the live destination outgoing IP addresses needed by the next lab task.

command -v gcloud >/dev/null 2>&1 || {
  echo "gcloud is required. Run this script in Google Cloud Shell." >&2
  exit 1
}

if ! command -v dig >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y dnsutils
fi

read -r -p "AWS RDS hostname: " RDS_HOSTNAME
[[ -n "$RDS_HOSTNAME" ]] || { echo "RDS hostname is required." >&2; exit 1; }

RDS_IP="$(dig +short "$RDS_HOSTNAME" A | tail -n 1)"
[[ "$RDS_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || {
  echo "Could not resolve an IPv4 address for $RDS_HOSTNAME" >&2
  exit 1
}

echo "Resolved RDS address: $RDS_IP"
read -r -s -p "RDS password [press Enter for changeme]: " DB_PASSWORD
printf '\n'
DB_PASSWORD="${DB_PASSWORD:-changeme}"

PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
[[ -n "$PROJECT_ID" && "$PROJECT_ID" != "(unset)" ]] || {
  echo "No Google Cloud project is configured." >&2
  exit 1
}

# The CLI requires an explicit profile ID. The lab's human-readable name is
# mysql-rds-source; using the same stable ID makes reruns easy to understand.
if gcloud database-migration connection-profiles describe mysql-rds-source \
    --project="$PROJECT_ID" --region=us-west1 >/dev/null 2>&1; then
  echo "Source connection profile already exists; leaving it unchanged."
else
  gcloud database-migration connection-profiles create mysql mysql-rds-source \
    --project="$PROJECT_ID" \
    --region=us-west1 \
    --host="$RDS_IP" \
    --port=3306 \
    --username=admin \
    --password="$DB_PASSWORD" \
    --display-name=mysql-rds-source \
    --no-async
fi

if gcloud sql instances describe mysql-cloudsql --project="$PROJECT_ID" >/dev/null 2>&1; then
  echo "Verified Cloud SQL destination instance: mysql-cloudsql"
else
  echo "Warning: mysql-cloudsql was not found or is not yet ready." >&2
fi

cat <<'INSTRUCTIONS'

Continue in Google Cloud Console > Database Migration > Migration jobs > Create migration job:

Get started
  Migration job name:     rds-to-cloudsql
  Migration job ID:       Keep the auto-generated value
  Source engine:          Amazon RDS for MySQL
  Destination region:     us-west1
  Migration job type:     One-time

Define a source
  Select the existing source profile: mysql-rds-source
  Click Save & continue.

Define a destination
  Type:                    Existing instance
  Instance ID:             mysql-cloudsql
  Click Select & continue.
  If confirmation appears, type mysql-cloudsql and confirm.

Define connectivity method
  Connectivity method:    IP allowlist
  Copy every Destination outgoing IP address shown by the wizard.
  Click Save & continue.

Configure migration databases
  Select objects to migrate: All databases
  Click Save & continue.

The migration job should now be saved as a draft. Do not start it yet;
Task 3 uses the copied destination IP addresses to update the AWS RDS allowlist.
INSTRUCTIONS
