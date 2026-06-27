#!/bin/bash -x

VERSION=5.23
NAME="test-neo4j-start-$VERSION"

set -e

docker rm -f ${NAME}

docker run --rm --env NEO4J_AUTH=none -d --name $NAME neo4j:$VERSION

# wait start
sleep 15

# test database
docker exec $NAME cypher-shell "SHOW DATABASES"

# stop neo4j
docker exec $NAME neo4j stop

# test database
docker exec $NAME cypher-shell "SHOW DATABASES"
