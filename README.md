# PostgreSQL with Automated Backups to Apillon on Akash Network

This repository contains everything needed to deploy a PostgreSQL database on Akash Network with automated backups to [Apillon](https://apillon.io/) storage every 12 hours.

## Quick Start

Go to [Akash Console](https://console.akash.network/) and use SDL configuration from this repository to deploy this template.

- [deploy.yaml](deploy.yaml) for default storage
- [deploy_shm.yaml](deploy_shm.yaml) for RAM storage

## Environment variable configuration

### PostgreSQL Configuration
- POSTGRES_HOST=postgres
- POSTGRES_PORT=5432
- POSTGRES_DB=mydatabase
- POSTGRES_USER=myuser
- POSTGRES_PASSWORD=mypassword

### Apillon Storage Configuration
- APILLON_BASIC_AUTH=your_basic_auth_key_here
- APILLON_BUCKET_UUID=your_bucket_uuid_here

### Backup Schedule
- BACKUP_INTERVAL=interval_in_seconds
