# oswatcher-deploy

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

> Docker Compose deployment stack for the [OSWatcher](https://github.com/OSWatcher) platform — a queryable graph of operating system evolution.

This repository orchestrates the full OSWatcher service stack:

```
                 ┌─────────────┐
   HTTPS ──────▶ │   Traefik   │ reverse proxy, TLS termination
                 └──────┬──────┘
              ┌─────────┴──────────┐
              ▼                    ▼
        ┌───────────┐        ┌───────────┐
        │ GraphQL   │        │   MinIO   │ S3-compatible blob storage
        │   API     │───────▶│           │ (file contents)
        └─────┬─────┘        └───────────┘
              ▼
        ┌───────────┐
        │   Neo4j   │ graph database (filesystem/registry/symbol history)
        │ + APOC    │ + oswatcher-procedures (custom tree-diff procedures)
        └───────────┘
```

| Service | Image | Role |
|---------|-------|------|
| **Neo4j** | `neo4j` | Graph database holding OS snapshots as Merkle trees |
| **procedure-init/builder** | `ghcr.io/oswatcher/oswatcher-procedures` | Installs the [custom Neo4j diff procedures](https://github.com/OSWatcher/oswatcher-procedures) JAR |
| **MinIO** | `minio/minio` | Object storage for file blobs |
| **API** | `ghcr.io/oswatcher/graphql-api` | GraphQL API over the graph |
| **Traefik** | `traefik` | Reverse proxy and TLS |
| **Frontend** | built from source (dev only) | Vue 3 web UI — deployed on GitHub Pages in production |

## Prerequisites

- Docker with the Compose plugin
- For development mode: sibling checkouts of the source repositories (see [Development](#development))

## Configuration

Copy the template and fill in your values:

```bash
cp .env.example .env
```

Every environment-specific value (versions, credentials, Auth0 tenant, domain) is set through `.env` — see the comments in [.env.example](.env.example). No configuration file in this repository needs editing.

## Development

Development mode builds the API, frontend, and Neo4j procedures from sibling checkouts (`../graphql-api`, `../osw-frontend`, `../oswatcher-procedures`):

```bash
docker compose -f compose.yml -f compose.dev.yml up --build
```

- Frontend: <http://localhost:5173>
- API: <http://api.localhost> (via Traefik) or <http://localhost:4000>
- Neo4j browser: <http://localhost:7474>
- MinIO console: <http://localhost:9001>

## Production

Production mode pulls pre-built images from GHCR and routes `api.<DOMAIN>` and `storage.<DOMAIN>` through Traefik:

```bash
docker compose -f compose.yml -f compose.prod.yml up -d
```

Production requires `DOMAIN`, `MINIO_ROOT_PASSWORD` (non-default), and `POSTHOG_PROJECT_API_KEY` to be set — fail-safe checks abort startup otherwise.

See [docs/deployment.md](docs/deployment.md) for the full deployment and rollback runbook.

## Backup & Restore

Scripts in [scripts/](scripts/) cover both stateful services:

```bash
./scripts/neo4j-backup.sh                                  # dump Neo4j
./scripts/minio-backup.sh                                  # archive MinIO data volume
./scripts/restore-backup-offline.sh <backup_file> [dev|prod]  # offline Neo4j restore
```

> **Warning:** never run `docker compose down -v` — it deletes the named volumes holding the database and blob storage.

## Related Repositories

| Repository | Purpose |
|------------|---------|
| [neogit](https://github.com/OSWatcher/neogit) | Core library — Neo4j + Merkle trees |
| [oswatcher-plugins](https://github.com/OSWatcher/oswatcher-plugins) | Capture/analysis plugins |
| [osw-builder](https://github.com/OSWatcher/osw-builder) | OS capture pipeline (ISO → graph) |
| [oswatcher-procedures](https://github.com/OSWatcher/oswatcher-procedures) | Custom Neo4j diff procedures |

## License

[Apache 2.0](LICENSE)
