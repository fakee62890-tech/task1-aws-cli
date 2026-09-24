# Task 1 — Install and configure AWS CLI

This script implements Task 1 of the lab **Migrating to Cloud SQL from Amazon RDS for MySQL Using Database Migration Service**.

It installs AWS CLI v2 in Google Cloud Shell when needed and runs `aws configure` interactively. It does not contain or upload credentials.

## Run in Cloud Shell

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/REPLACE_OWNER/task1-aws-cli/main/setup-aws-cli.sh)
```

When prompted, enter the lab-provided AWS Access Key ID and Secret Access Key, use `us-east-1` as the default region, and leave the output format blank.
