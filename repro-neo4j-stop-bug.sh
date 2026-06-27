#!/bin/bash

set -e

echo "=== Neo4j Stop Bug Reproduction Script ==="
echo

# Test 1: Working case (default config)
echo "1. Testing DEFAULT configuration (should work)..."
docker run --rm --env NEO4J_AUTH=none -d --name test-working neo4j:5.23 > /dev/null
echo "   Container started, waiting 15s for Neo4j to start..."
sleep 15

echo "   Testing connection..."
docker exec test-working cypher-shell "SHOW DATABASES" > /dev/null && echo "   ✅ Neo4j is running"

echo "   Attempting to stop Neo4j..."
if docker exec test-working neo4j stop 2>&1 | grep -q "Stopping Neo4j"; then
    echo "   ✅ neo4j stop worked (container should exit)"
else
    echo "   ❌ neo4j stop failed"
fi

echo

# Test 2: Broken case (with NEO4J_server_directories_run)
echo "2. Testing with NEO4J_server_directories_run='/run' (should be broken)..."
docker run --rm --env NEO4J_AUTH=none --env NEO4J_server_directories_run='/run' -d --name test-broken neo4j:5.23 > /dev/null
echo "   Container started, waiting 15s for Neo4j to start..."
sleep 15

echo "   Testing connection..."
docker exec test-broken cypher-shell "SHOW DATABASES" > /dev/null && echo "   ✅ Neo4j is running"

echo "   Checking for PID file..."
if docker exec test-broken find / -name "neo4j.pid" 2>/dev/null | grep -q neo4j.pid; then
    echo "   ✅ PID file found"
else
    echo "   ❌ No PID file found"
fi

echo "   Attempting to stop Neo4j..."
STOP_OUTPUT=$(docker exec test-broken neo4j stop 2>&1)
echo "   Output: $STOP_OUTPUT"

echo "   Testing connection after 'stop'..."
if docker exec test-broken cypher-shell "SHOW DATABASES" > /dev/null 2>&1; then
    echo "   ❌ Neo4j is still running! (This is the bug)"
else
    echo "   ✅ Neo4j stopped successfully"
fi

echo "   Cleaning up..."
docker stop test-broken > /dev/null

echo
echo "=== Bug reproduction complete ==="
echo "Expected: Test 1 should work, Test 2 should show the bug"