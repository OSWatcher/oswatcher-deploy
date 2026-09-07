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
| **Frontend** | `ghcr.io/oswatcher/frontend` | Vue 3 web UI — published image in prod mode, sibling checkout in dev |

## Run OSWatcher

The production overlay runs the published images, both on your own machine and on a server.
Clone only this repository:

```bash
git clone https://github.com/OSWatcher/oswatcher-deploy
cd oswatcher-deploy
```

The repository includes local defaults; no configuration or password setup is needed.
Then start the stack:

```bash
docker compose up -d
```

The committed `.env` selects `compose.yml` and `compose.prod.yml`. It defaults to HTTP on
localhost, loopback-only published ports and modest
Neo4j memory settings. No domain registration, TLS certificate or analytics key is needed.

Open **<http://localhost>**. Other endpoints:

- GraphQL API: <http://api.localhost/graphql> or <http://localhost:4000/graphql>
- Neo4j browser: <http://localhost:7474>
- MinIO console: <http://localhost:9001>

Verify the API:

```bash
curl --fail -s -X POST http://localhost:4000/graphql \
  -H 'Content-Type: application/json' \
  -d '{"query":"{ branches { name } }"}'
# {"data":{"branches":[]}}
```

A fresh graph is empty. A ready-to-use database download is planned; until it is published,
use [osw-builder](https://github.com/OSWatcher/osw-builder) to build and capture OS images.
Starting the services does not create an OS corpus.

Stop the stack while keeping its data:

```bash
docker compose down
```

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
build context until an overlay supplies one. The template selects the production overlay by
default. The explicit `-f` flags above override that selection for development.

Development mode needs no registry credentials, no domain and no PostHog key, which makes
it suitable for developing the services. Use the quickstart above to evaluate the published images.

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

## Deploy on a server

Use the same `compose.prod.yml` overlay. Edit `.env` to set `DOMAIN` to your domain,
`HTTP_SCHEME=https`, and `BIND_ADDRESS` to the server interface you intend to expose.
Replace the local MinIO credentials, then configure DNS and a trusted TLS certificate for `<DOMAIN>`, `api.<DOMAIN>` and
`storage.<DOMAIN>`. Certificate provisioning is not automated by this repository;
Traefik otherwise serves its default self-signed certificate.

Configure Neo4j authentication and size its heap/page cache for your corpus. `BIND_ADDRESS`
applies to all published service ports, including the database and storage; restrict those
ports through your firewall when exposing the proxy publicly.

The MinIO root password must be non-default. PostHog analytics is optional.
For existing deployments without `HTTP_SCHEME` or memory overrides, HTTPS routing and the
previous server memory defaults are retained.

```bash
docker compose up -d
```

If an existing `.env` does not set `COMPOSE_FILE`, use the explicit equivalent:

```bash
docker compose -f compose.yml -f compose.prod.yml up -d
```

See [docs/deployment.md](docs/deployment.md) for the deployment and rollback runbook.

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
