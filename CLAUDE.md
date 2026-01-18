# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains deployment configurations for Grapheos, a Neo4j-based application stack. The project uses Docker Compose for multi-service orchestration and Ansible for deployment automation.

## Core Commands

### Development Environment
```bash
# Start development environment with build
docker compose -f compose.yml -f compose.dev.yml up --build

# Stop development environment
docker compose -f compose.yml -f compose.dev.yml down
```

### Production Environment
```bash
# Start production environment
docker compose -f compose.yml -f compose.prod.yml up -d

# Stop production environment
docker compose -f compose.yml -f compose.prod.yml down
```

### Neo4j Backup & Restore
```bash
# Restore from Neo4j backup dump (offline restore)
./scripts/restore-backup-offline.sh <backup_file> [dev|prod]

# Example: Restore to development environment
./scripts/restore-backup-offline.sh backups/neo4j-backup.dump dev
```

### MinIO Backup
```bash
# Create compressed backup of MinIO data volume
./scripts/minio-backup.sh

# Backups are saved to backups/minio-backup-YYYYMMDD_HHMMSS.tar.xz
```

### MinIO Administration (mc client)
```bash
# Access mc client from within the running MinIO container
docker compose -f compose.yml -f compose.dev.yml exec minio mc [command]

# List buckets
docker compose -f compose.yml -f compose.dev.yml exec minio mc ls local/

# Set bucket policy (private/public/download/upload)
docker compose -f compose.yml -f compose.dev.yml exec minio mc anonymous set none local/bucket-name

# Create dedicated user for blob downloads (recommended over using root credentials)
PASSWORD=$(openssl rand -base64 24)
docker compose -f compose.yml -f compose.dev.yml exec minio mc admin user add local/ api-blob-download "$PASSWORD"
docker compose -f compose.yml -f compose.dev.yml exec minio mc admin policy attach local/ readonly --user api-blob-download
echo "Credentials - Username: api-blob-download, Password: $PASSWORD"

# List users
docker compose -f compose.yml -f compose.dev.yml exec minio mc admin user list local/
```

### Ansible Deployment
```bash
# Deploy GitHub Actions runners to ops.grapheos.cc
cd ansible
export GITHUB_TOKEN="your_token"
ansible-playbook -i inventory.yml site.yml

# Deploys 20 self-hosted runners (builder-1 to builder-20) for OSWatcher/osw-builder
# Modify roles/runner/vars/main.yml to change runner configuration
```

## Environment Configuration

The project uses environment files for configuration:
- `.env` - Default configuration for development/test
- `.env.prod` - Production overrides (minimal, only critical vars)
- `.env.test` - Test environment configuration

Key environment variables:
- `NEO4J_VERSION`, `MINIO_VERSION`, `TRAEFIK_VERSION` - Service versions
- `NEO4J_AUTH` - Set to `none` in dev/test, use credentials in prod
- `MINIO_ROOT_USER/PASSWORD` - MinIO admin credentials (must change in prod)
- `AUTH0_DOMAIN_URI`, `AUTH0_AUDIENCE` - Auth0 authentication config
- `POSTHOG_PROJECT_API_KEY` - Analytics key (required in prod)
- `RESTRICTED_BRANCH_NAME` - Branch restriction in API (e.g., "windows", "master")
- `NEO4J_GRAPHQL_DEBUG_LVL` - GraphQL debug level (dev only)

## Architecture

### Service Stack
- **Neo4j**: Graph database with APOC plugin and custom procedures
- **MinIO**: S3-compatible object storage
- **API**: GraphQL API service (built from `../graphql-api`)
- **Frontend**: React application (built from `../osw-frontend`, dev only)
- **Traefik**: Reverse proxy with SSL termination
- **procedure-builder** (dev): Builds Neo4j procedure JAR from `../grapheos-procedures`
- **procedure-init** (prod): Pulls procedure JAR from `ghcr.io/oswatcher/grapheos-procedures`

### Environment Differences
- **Development**:
  - Uses local builds for API and frontend
  - Builds Neo4j procedures from `../grapheos-procedures` via `procedure-builder`
  - Traefik configured for localhost with self-signed certificates
  - Neo4j has verbose query logging enabled
  - Frontend runs on port 8080

- **Production**:
  - Uses pre-built Docker images from GitHub Container Registry
  - Pulls Neo4j procedures from `ghcr.io/oswatcher/grapheos-procedures` via `procedure-init`
  - Traefik configured for `*.grapheos.cc` domains with Cloudflare SSL
  - Neo4j optimized for 12GB memory systems
  - Frontend deployed separately on GitHub Pages

### Key Configuration Files
- `compose.yml`: Base service definitions
- `compose.dev.yml`: Development overrides
- `compose.prod.yml`: Production overrides with security checks
- `certs/dev.yml`: Development SSL configuration (self-signed)
- `.env`: Environment variables (dev/test defaults)
- `.env.prod`: Production environment variable overrides
- `.env.test`: Test environment configuration

## Important Notes

### Named Volumes - CRITICAL
- **NEVER use `docker compose down -v`** - this removes named volumes including `neo4j_data` which requires manual restoration from backup
- Use `docker compose down` (without `-v`) to stop services while preserving data

### Neo4j Custom Procedures
- Custom procedures are provided by the `grapheos-procedures` repository (`../grapheos-procedures`)
- The JAR is stored in the `procedure_plugin` named volume and mounted to Neo4j's `/plugins` directory
- **Dev**: `procedure-builder` service builds the JAR from local source and copies it to the volume
- **Prod**: `procedure-init` service pulls from `ghcr.io/oswatcher/grapheos-procedures:latest` and copies the JAR
- Neo4j waits for the init container to complete before starting (`service_completed_successfully`)

### Production Requirements
- `MINIO_ROOT_PASSWORD` must be set (default password is rejected)
- `POSTHOG_PROJECT_API_KEY` must be set
- Uses pre-built images from `ghcr.io/oswatcher/graphql-api:latest` and `ghcr.io/oswatcher/grapheos-procedures:latest`
- Production compose includes security checks that prevent startup with default passwords

### Neo4j Configuration
- Authentication is disabled in dev/test (`NEO4J_AUTH=none`)
- Unlimited transaction memory (`NEO4J_dbms_memory_transaction_total_max: 0`)
- Increased Bolt thread pool (800 threads) to avoid starvation
- tmpfs mount at `/var/lib/neo4j/run` to avoid "already running" issues
- Restore process requires stopping the service and uses `neo4j-admin` container

### MinIO Configuration
- Backups use maximum xz compression (`-9`) for space efficiency
- Create dedicated users for specific access patterns (e.g., `api-blob-download` for readonly access)
- Avoid using root credentials (`MINIO_ROOT_USER/PASSWORD`) in applications
- Set appropriate bucket policies (`private`, `public`, `download`, `upload`)
- The `mc` client is available inside the MinIO container for administration

### Other
- `RESTRICTED_BRANCH_NAME` environment variable controls branch restrictions in the API

## Related Repositories

- `../graphql-api` - GraphQL API service (GitHub: `OSWatcher/graphql-api`)
- `../grapheos-procedures` - Neo4j custom procedures (GitHub: `OSWatcher/grapheos-procedures`)
- `../osw-frontend` - Frontend application (GitHub: `OSWatcher/osw-frontend`)