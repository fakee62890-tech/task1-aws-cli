#!/usr/bin/env bash
set -euo pipefail

# Check Task 2 Database Migration Service status in Google Cloud Shell.
command -v gcloud >/dev/null 2>&1 || {
  echo "gcloud is required. Run this script in Google Cloud Shell." >&2
  exit 1
}

PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
[[ -n "$PROJECT_ID" && "$PROJECT_ID" != "(unset)" ]] || {
  echo "No Google Cloud project is configured." >&2
  exit 1
}

REGION="us-west1"

echo "Project: $PROJECT_ID"
echo
echo "Source connection profile:"
gcloud database-migration connection-profiles describe mysql-rds-source \
  --project="$PROJECT_ID" --region="$REGION" \
  --format='yaml(name,displayName,state,provider,providerDetails.mysql)' \
  || echo "Source profile mysql-rds-source was not found."

echo
echo "Migration jobs in $REGION:"
gcloud database-migration migration-jobs list \
  --project="$PROJECT_ID" --region="$REGION" \
  --format='table(name.basename():label=JOB_ID,displayName:label=NAME,state:label=STATE,phase:label=PHASE)' \
  || true

echo
echo "Interpretation:"
echo "  DRAFT/CREATING = created but not running"
echo "  RUNNING        = migration is currently running"
echo "  COMPLETED      = migration finished successfully"
echo "  FAILED         = migration failed; run describe for details"
