#!/usr/bin/env bash
set -euo pipefail

# GSP355 Task 1: prepare postgres-vm for a DMS PostgreSQL migration.
# This script changes only the postgres-vm source VM. It does not create or
# start the DMS migration job.

command -v gcloud >/dev/null 2>&1 || {
  echo "gcloud required. Is script ko Google Cloud Shell mein run karo." >&2
  exit 1
}

PROJECT_ID="$(gcloud config get-value project 2>/dev/null)"
[[ -n "$PROJECT_ID" && "$PROJECT_ID" != "(unset)" ]] || {
  echo "Google Cloud project configured nahi hai." >&2
  exit 1
}

VM_NAME="$(gcloud compute instances list --project="$PROJECT_ID" \
  --format='value(name)' | grep -E '^(postgres-vm|postgresql-vm)$' | head -n 1 || true)"
ZONE="$(gcloud compute instances describe "$VM_NAME" --project="$PROJECT_ID" \
  --format='value(zone)' 2>/dev/null || true)"
[[ -n "$ZONE" ]] || {
  echo "postgres-vm ya postgresql-vm nahi mila. Lab project/VM check karo." >&2
  exit 1
}

VM_IP="$(gcloud compute instances describe "$VM_NAME" --project="$PROJECT_ID" \
  --zone="$ZONE" --format='value(networkInterfaces[0].networkIP)')"

echo "Project: $PROJECT_ID"
echo "VM: $VM_NAME"
echo "Zone: $ZONE"
echo "Internal IP: $VM_IP"
echo
echo "$VM_NAME par PostgreSQL 14 + pglogical configure hoga."
read -r -s -p "Migration user password: " MIGRATION_PASSWORD
printf '\n'
[[ -n "$MIGRATION_PASSWORD" ]] || { echo "Password required hai." >&2; exit 1; }

REMOTE_SCRIPT=$(cat <<'REMOTE'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y postgresql-14-pglogical

CONF=/etc/postgresql/14/main/postgresql.conf
HBA=/etc/postgresql/14/main/pg_hba.conf

# Append an explicit final block so the required values win over earlier defaults.
if ! grep -q '^# BEGIN GSP355 DMS CONFIG$' "$CONF"; then
cat >> "$CONF" <<'PGCONF'

# BEGIN GSP355 DMS CONFIG
listen_addresses = '*'
wal_level = logical
max_wal_senders = 10
max_replication_slots = 10
shared_preload_libraries = 'pglogical'
# END GSP355 DMS CONFIG
PGCONF
fi

if ! grep -q '^# BEGIN GSP355 DMS HBA$' "$HBA"; then
cat >> "$HBA" <<'PGHBA'

# BEGIN GSP355 DMS HBA
host    all    all    0.0.0.0/0    md5
host    all    all    ::/0         md5
# END GSP355 DMS HBA
PGHBA
fi

systemctl restart postgresql
systemctl is-active --quiet postgresql

sudo -u postgres psql -d orders -v ON_ERROR_STOP=1 <<'SQL'
CREATE EXTENSION IF NOT EXISTS pglogical;
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'replication_user') THEN
    CREATE ROLE replication_user LOGIN REPLICATION PASSWORD '__MIGRATION_PASSWORD__';
  ELSE
    ALTER ROLE replication_user WITH LOGIN REPLICATION PASSWORD '__MIGRATION_PASSWORD__';
  END IF;
END
$$;
GRANT CONNECT ON DATABASE orders TO replication_user;
GRANT USAGE ON SCHEMA public TO replication_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replication_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO replication_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO replication_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO replication_user;
SQL

missing_keys=$(sudo -u postgres psql -d orders -At -v ON_ERROR_STOP=1 -c "
SELECT c.relname
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r' AND n.nspname = 'public'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.oid AND i.indisprimary
  )
ORDER BY c.relname;")

if [[ -n "$missing_keys" ]]; then
  echo "ERROR: In tables mein primary key missing hai:" >&2
  printf '%s\n' "$missing_keys" >&2
  echo "Primary keys add karke script dobara run karo." >&2
  exit 1
fi

echo "PostgreSQL VM preparation complete. All public tables have primary keys."
sudo -u postgres psql -d orders -At -c "SELECT extname FROM pg_extension WHERE extname='pglogical';"
REMOTE
)

REMOTE_SCRIPT="${REMOTE_SCRIPT//__MIGRATION_PASSWORD__/$MIGRATION_PASSWORD}"

PAYLOAD="$(printf '%s' "$REMOTE_SCRIPT" | base64 -w0)"
gcloud compute ssh "$VM_NAME" --project="$PROJECT_ID" --zone="$ZONE" \
  --command="echo '$PAYLOAD' | base64 -d | sudo bash"

echo
echo "Task 1 source preparation complete."
echo "Use this internal IP when creating the DMS PostgreSQL source profile: $VM_IP"
echo "DMS region: europe-west4"
