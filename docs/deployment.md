# Deployment Procedures

This document describes updates to the published-image stack. The same production overlay
runs locally or on a server. The committed `.env` selects it for plain `docker compose`
commands; explicit `-f` commands also work with older `.env` files.

## Prerequisites

Before deploying, ensure:
- You have SSH access to your production server
- The deployment directory contains this repository with a configured `.env`
- The API Docker image has been built and pushed to GHCR (via CI/CD)

## Deployment Procedure: GraphQL API

### Step 1: Connect to the Production Server

```bash
ssh <your-server>
```

### Step 2: Navigate to the Deployment Directory

```bash
cd ~/oswatcher-deploy
```

### Step 3: Pull and Recreate the API Container

```bash
docker compose -f compose.yml -f compose.prod.yml up -d --force-recreate api
```

**What this does:**
- `compose.yml` - Base configuration
- `compose.prod.yml` - Production overrides
- `up -d` - Start containers in detached mode
- `--force-recreate` - Force recreation even if configuration hasn't changed
- `api` - Target only the API service (leaves Neo4j running)

**Note:** The OSWatcher images on GHCR are public and can be pulled anonymously. If you are deploying images from a private registry, authenticate first with `docker login ghcr.io` using a PAT with `read:packages` scope.

### Step 4: Verify Deployment

```bash
# Check container status
docker compose ps

# View API logs
docker compose logs -f api

# Test API health endpoint (if available)
curl http://localhost:4000/health
```

## Deployment Procedure: Frontend

The frontend uses the public `ghcr.io/oswatcher/frontend:latest` image. Its entrypoint applies
`VITE_OSWATCHER_API_URI` at container start, using `<HTTP_SCHEME>://api.<DOMAIN>` from the production configuration (HTTPS if unset).

```bash
docker compose -f compose.yml -f compose.prod.yml up -d --pull always frontend
```

`--pull always` fetches the latest published image before recreating the frontend.

## Rollback Procedure

If the deployment fails or introduces issues:

```bash
# View available image tags
docker images ghcr.io/oswatcher/graphql-api

# Rollback to previous version
docker compose -f compose.yml -f compose.prod.yml down api
# Edit compose.prod.yml to specify previous image tag
docker compose -f compose.yml -f compose.prod.yml up -d api
```

## Troubleshooting

### Container Pull Failures

**Problem:** "Error response from daemon: pull access denied"

**Solution:**
- Verify the image exists on GitHub Container Registry
- Check image visibility (public vs private)
- For private images, ensure you're authenticated: `docker login ghcr.io`

### API Container Fails to Start

**Problem:** Container exits immediately after `up`

**Solution:**
```bash
# Check logs for error messages
docker compose logs api

# Common issues:
# - Database connection failure (check Neo4j is running)
# - Environment variable misconfiguration (check .env)
# - Port conflicts (check port 4000 availability)
```

### Neo4j Connection Issues

**Problem:** API can't connect to Neo4j

**Solution:**
```bash
# Verify Neo4j is running
docker compose ps neo4j

# Check Neo4j logs
docker compose logs neo4j

# Test Neo4j connectivity
docker compose exec api nc -zv neo4j 7687
```

## Best Practices

1. **Always test in development first:**
   ```bash
   docker compose -f compose.yml -f compose.dev.yml up --build
   ```

2. **Monitor logs during deployment:**
   ```bash
   docker compose logs -f api
   ```

3. **Use specific image tags (not `latest`):**
   - Edit `compose.prod.yml` to pin versions
   - Example: `ghcr.io/oswatcher/graphql-api:v1.2.3`

4. **Backup before major updates:**
   - See `scripts/neo4j-backup.sh` and `scripts/minio-backup.sh`

## Related Documentation

- [Docker Compose Configuration](../compose.yml)
- [Production Configuration](../compose.prod.yml)
- [Ansible Automation](../ansible/README.md)
