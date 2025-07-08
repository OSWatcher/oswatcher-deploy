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
# Create backup (defaults to dev-neo4j-1 container)
./neo4j-backup-restore.sh backup [container_name]

# Restore from backup
./neo4j-backup-restore.sh restore [filename] [container_name]

# List available backups
./neo4j-backup-restore.sh list

# Copy data between volumes
./neo4j-backup-restore.sh copy-volume [source_volume] [target_volume]
```

### Ansible Deployment
```bash
# Deploy to remote servers
cd ansible
ansible-playbook -i inventory.yml site.yml
```

## Architecture

### Service Stack
- **Neo4j**: Graph database with APOC plugin and custom procedures
- **MinIO**: S3-compatible object storage
- **API**: GraphQL API service (built from `../graphql-api`)
- **Frontend**: React application (built from `../osw-frontend`, dev only)
- **Traefik**: Reverse proxy with SSL termination

### Environment Differences
- **Development**: 
  - Uses local builds for API and frontend
  - Traefik configured for localhost with self-signed certificates
  - Neo4j has verbose query logging enabled
  - Frontend runs on port 8080

- **Production**:
  - Uses pre-built Docker images from GitHub Container Registry
  - Traefik configured with Let's Encrypt for `*.grapheos.cc` domains
  - Neo4j optimized for 12GB memory systems
  - Frontend deployed separately on GitHub Pages

### Key Configuration Files
- `compose.yml`: Base service definitions
- `compose.dev.yml`: Development overrides
- `compose.prod.yml`: Production overrides
- `certs/dev.yml`: Development SSL configuration
- `certs/prod.yml`: Production SSL configuration

## Important Notes

- Neo4j uses a custom procedure JAR at `./plugins/procedure.jar`
- Production environment assumes external dependencies are available at their respective repositories
- Ansible deployment requires proper inventory configuration in `ansible/inventory.yml`
- All services use environment variables for configuration - check for `.env` files
- Neo4j backup script requires manual configuration of `BACKUP_DIR` path