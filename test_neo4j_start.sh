#!/bin/bash

set -ex

PROJECT="test_neo4j_start"

# remove project if exists
docker compose -f compose.yml -f compose.dev.yml -p $PROJECT down -v

# create container
docker compose -f compose.yml -f compose.dev.yml -p $PROJECT up -d neo4j

sleep 15s

# test
docker compose -f compose.yml -f compose.dev.yml -p $PROJECT exec neo4j cypher-shell "SHOW DATABASES"

# stop db
docker compose -f compose.yml -f compose.dev.yml -p $PROJECT exec neo4j neo4j stop

# test
docker compose -f compose.yml -f compose.dev.yml -p $PROJECT exec neo4j cypher-shell "SHOW DATABASES"
