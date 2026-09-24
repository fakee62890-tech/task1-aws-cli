# Task 1 — Install and configure AWS CLI

This script implements Task 1 of the lab **Migrating to Cloud SQL from Amazon RDS for MySQL Using Database Migration Service**.

It installs AWS CLI v2 in Google Cloud Shell when needed and runs `aws configure` interactively. It does not contain or upload credentials.

## Run in Cloud Shell

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fakee62890-tech/task1-aws-cli/main/setup-aws-cli.sh)
```

When prompted, enter the lab-provided AWS Access Key ID and Secret Access Key, use `us-east-1` as the default region, and leave the output format blank.

## Task 2 — Create the RDS source connection profile

Run the Task 2 script in authenticated Google Cloud Shell:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fakee62890-tech/task1-aws-cli/master/task2-create-source-profile.sh)
```

Enter the AWS RDS hostname when prompted. The script resolves its IPv4 address with `dig`, then creates the `mysql-rds-source` MySQL connection profile in `us-west1` using port `3306`, username `admin`, and the lab password (default `changeme`). It does not store credentials.

The remaining migration-job wizard steps require the destination Cloud SQL instance details and should be completed after the lab provides them.

## Full Task 2 — Create the one-time migration job

The full helper verifies the existing `mysql-cloudsql` destination instance, creates the source profile if needed, and prints the exact Google Cloud console values for the remaining wizard steps. Run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fakee62890-tech/task1-aws-cli/master/task2-full-migration-job.sh)
```

The script intentionally does not start the migration or modify the AWS RDS allowlist. Copy the destination outgoing IP addresses from the wizard and keep the job in draft state for Task 3.
