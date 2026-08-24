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
| **Frontend** | built from [`OSWatcher/frontend`](https://github.com/OSWatcher/frontend) | Vue 3 web UI — built from sibling checkout in dev, directly from the GitHub repo in prod |

## Prerequisites

- Docker with the Compose plugin
- For development mode: sibling checkouts of the source repositories (see [Development](#development))
- For production mode: no local checkouts needed — the frontend is built directly from the `OSWatcher/frontend` GitHub repo

## Configuration

Copy the template and fill in your values:

```bash
cp .env.example .env
```

Every environment-specific value (versions, credentials, domain) is set through `.env` — see the comments in [.env.example](.env.example). No configuration file in this repository needs editing.

## Development

Development mode builds the API, frontend, and Neo4j procedures from sibling checkouts. Clone all
three next to this repository first, or the build fails on missing contexts:

```bash
cd ..
git clone https://github.com/OSWatcher/graphql-api
git clone https://github.com/OSWatcher/frontend
git clone https://github.com/OSWatcher/oswatcher-procedures
cd oswatcher-deploy

docker compose -f compose.yml -f compose.dev.yml up -d --build
```

`compose.yml` is a base layer and is not runnable on its own: the `api` service has no image or
build context until an overlay supplies one. Always pass `-f compose.yml` plus either
`-f compose.dev.yml` or `-f compose.prod.yml`.

Development mode needs no registry credentials, no domain and no PostHog key, which makes
it the mode to use for evaluating the project or working on it locally.

- Frontend: <http://localhost:5173>
- API: <http://api.localhost> (via Traefik) or <http://localhost:4000>
- Neo4j browser: <http://localhost:7474>
- MinIO console: <http://localhost:9001>

Smoke test:

```bash
curl -s -X POST http://localhost:4000/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ branches { name } }"}'
# {"data":{"branches":[]}}
```

An empty `branches` list is correct on a fresh deployment: the graph starts empty and is filled with
[osw-builder](https://github.com/OSWatcher/osw-builder).

## Production

Production mode pulls pre-built images from GHCR for the API, frontend and Neo4j procedures, and routes `<DOMAIN>` (frontend), `api.<DOMAIN>`, and `storage.<DOMAIN>` through Traefik:

```bash
docker compose -f compose.yml -f compose.prod.yml up -d --build
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
| [frontend](https://github.com/OSWatcher/frontend) | Vue 3 web UI |

## License

[Apache 2.0](LICENSE)
