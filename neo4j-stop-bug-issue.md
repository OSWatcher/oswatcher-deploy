# `neo4j stop` fails silently when `NEO4J_server_directories_run` is set to `/run`

I discovered that when I set the environment variable `NEO4J_server_directories_run` to `/run`, the `neo4j stop` command incorrectly reports "Neo4j is not running" even though Neo4j is actively running and accepting connections.

**Neo4j Version:** 5.23, 5.26.12, 2025.08
**Operating System:** Linux (Docker containers)
**Installation Method:** Docker
**API:** Docker + cypher-shell

### Steps to reproduce

**Working case (default configuration):**
1. Start Neo4j container: `docker run --rm --env NEO4J_AUTH=none -d --name test-working neo4j:5.23`
2. Wait for startup: `sleep 15`  
3. Test connection: `docker exec test-working cypher-shell "SHOW DATABASES"`
4. Stop Neo4j: `docker exec test-working neo4j stop`

**Broken case (with NEO4J_server_directories_run):**
1. Start Neo4j container: `docker run --rm --env NEO4J_AUTH=none --env NEO4J_server_directories_run='/run' -d --name test-broken neo4j:5.23`
2. Wait for startup: `sleep 15`
3. Test connection: `docker exec test-broken cypher-shell "SHOW DATABASES"`
4. Try to stop Neo4j: `docker exec test-broken neo4j stop`
5. Test connection again: `docker exec test-broken cypher-shell "SHOW DATABASES"`

### Expected behavior
The `neo4j stop` command should successfully stop the Neo4j process or provide a meaningful error message if it cannot.

### Actual behavior
- Step 4 outputs: "Neo4j is not running"
- Step 5 shows Neo4j is still running and accepting connections
- The `neo4j stop` command fails to stop the actual Neo4j process

### Root cause analysis
When `NEO4J_server_directories_run='/run'` is configured, Neo4j cannot write its PID file to `/run/neo4j.pid` due to insufficient permissions. The `neo4j stop` command relies on this PID file to identify which process to terminate.

**Evidence:**
- Working container: PID file exists at `/var/lib/neo4j/run/neo4j.pid`
- Broken container: `find / -name "neo4j.pid"` returns no results

### Impact
This configuration is commonly used in production deployments to avoid "neo4j is already running" issues (referenced in issue #12908), but it breaks the standard shutdown mechanism.

### Workaround
Use container-level commands: `docker stop <container>` instead of `docker exec <container> neo4j stop`