#!/usr/bin/env bash
set -euo pipefail

# WARNING: Destructive cleanup for the current Google Cloud project.
# Deletes all Database Migration Service jobs and connection profiles in REGION.
# Nothing is deleted unless the user types the exact confirmation: DELETE ALL

command -v gcloud >/dev/null 2>&1 || {
  echo "gcloud required. Is script ko Google Cloud Shell mein run karo." >&2
  exit 1
}

PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
REGION="${REGION:-us-west1}"
[[ -n "$PROJECT_ID" && "$PROJECT_ID" != "(unset)" ]] || {
  echo "Google Cloud project configured nahi hai." >&2
  exit 1
}

echo "Project: $PROJECT_ID"
echo "Region:  $REGION"
echo
echo "Migration jobs jo delete honge:"
mapfile -t JOBS < <(gcloud database-migration migration-jobs list \
  --project="$PROJECT_ID" --region="$REGION" --format='value(name)' 2>/dev/null || true)
if ((${#JOBS[@]} == 0)); then echo "  (none)"; else printf '  %s\n' "${JOBS[@]}"; fi

echo
echo "Connection profiles jo delete honge:"
mapfile -t PROFILES < <(gcloud database-migration connection-profiles list \
  --project="$PROJECT_ID" --region="$REGION" --format='value(name)' 2>/dev/null || true)
if ((${#PROFILES[@]} == 0)); then echo "  (none)"; else printf '  %s\n' "${PROFILES[@]}"; fi

echo
echo "WARNING: Ye action reversible nahi hai."
read -r -p "Confirm karne ke liye exactly DELETE ALL type karo: " CONFIRM
if [[ "$CONFIRM" != "DELETE ALL" ]]; then
  echo "Cancel kar diya. Kuch bhi delete nahi hua."
  exit 0
fi

for job in "${JOBS[@]}"; do
  [[ -n "$job" ]] || continue
  echo "Deleting migration job: $job"
  gcloud database-migration migration-jobs delete "$job" \
    --project="$PROJECT_ID" --region="$REGION" --quiet --no-async
done

for profile in "${PROFILES[@]}"; do
  [[ -n "$profile" ]] || continue
  echo "Deleting connection profile: $profile"
  gcloud database-migration connection-profiles delete "$profile" \
    --project="$PROJECT_ID" --region="$REGION" --quiet --no-async
done

echo
echo "Cleanup complete. Migration jobs aur connection profiles delete ho gaye."
