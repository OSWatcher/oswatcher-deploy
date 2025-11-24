# Deployment Procedures

This document describes the operational procedures for deploying updates to the GraphEOS production environment.

## Production Server

**Host:** `ops.grapheos.cc`
**User:** `ops`
**Working Directory:** `~/grapheos-deploy`

## Prerequisites

Before deploying, ensure:
- You have SSH access to `ops.grapheos.cc` with agent forwarding
- You have GitHub Container Registry (GHCR) credentials
- The API Docker image has been built and pushed to GHCR (via CI/CD)

## Deployment Procedure: GraphQL API

### Step 1: Connect to Production Server

```bash
ssh -A ops.grapheos.cc
```

The `-A` flag enables SSH agent forwarding for accessing private repositories.

### Step 2: Navigate to Deployment Directory

```bash
cd ~/grapheos-deploy
```

### Step 3: Authenticate with GitHub Container Registry

```bash
sudo -E docker login ghcr.io -u wenzel
```

When prompted, enter your GitHub Personal Access Token (PAT) with `read:packages` permission.

**Note:** The `-E` flag preserves environment variables when using sudo.

**Warning:** Credentials are stored unencrypted in `/home/ops/.docker/config.json`. Consider configuring a credential helper for enhanced security.

### Step 4: Pull and Recreate API Container

```bash
docker compose -f compose.yml -f compose.prod.yml up -d --force-recreate api
```

**What this does:**
- `compose.yml` - Base configuration
- `compose.prod.yml` - Production overrides
- `up -d` - Start containers in detached mode
- `--force-recreate` - Force recreation even if configuration hasn't changed
- `api` - Target only the API service (leaves Neo4j running)

**Expected Output:**
```
[+] Running 10/10
 ✔ api Pulled                          6.0s
   ✔ 9824c27679d3 Already exists        0.0s
   [... layer pulls ...]
[+] Running 2/2
 ✔ Container grapheos-deploy-neo4j-1  Running
 ✔ Container grapheos-deploy-api-1    Started
```

### Step 5: Verify Deployment

```bash
# Check container status
docker compose ps

# View API logs
docker compose logs -f api

# Test API health endpoint (if available)
curl http://localhost:4000/health
```

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

### Authentication Issues

**Problem:** `docker login` fails with "unauthorized"

**Solution:**
- Verify your GitHub PAT has `read:packages` scope
- Check token expiration date
- Generate new token if necessary: https://github.com/settings/tokens

### Container Pull Failures

**Problem:** "Error response from daemon: pull access denied"

**Solution:**
- Ensure you're authenticated: `docker login ghcr.io`
- Verify image exists: Check GitHub Container Registry
- Check image visibility (public vs private)

### API Container Fails to Start

**Problem:** Container exits immediately after `up`

**Solution:**
```bash
# Check logs for error messages
docker compose logs api

# Common issues:
# - Database connection failure (check Neo4j is running)
# - Environment variable misconfiguration (check .env.prod)
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
   ```bash
   # See backups/README.md for Neo4j backup procedures
   ```

5. **Coordinate with team:**
   - Announce deployment in team chat
   - Schedule during low-traffic periods
   - Have rollback plan ready

## Related Documentation

- [Docker Compose Configuration](../compose.yml)
- [Production Configuration](../compose.prod.yml)
- [Neo4j Backup Procedures](../backups/README.md)
- [Ansible Automation](../ansible/README.md)

## Emergency Contacts

- **Infrastructure:** @wenzel
- **API Issues:** @graphql-api-team
- **Database Issues:** @neo4j-team
