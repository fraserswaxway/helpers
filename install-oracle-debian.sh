#!/bin/bash
# curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/install-oracle-debian.sh | bash
#

rm -rf /opt/oracle
mkdir -p /opt/oracle/oradata
mkdir -p /opt/oracle/tablespace
chmod -R 777 /opt/oracle

docker run --name sentineldb --hostname sentineldb \
  -p 1521:1521 \
  -e ORACLE_PWD=axway \
  -v /opt/oracle/oradata:/opt/oracle/oradata \
  -v /opt/oracle/tablespace:/opt/oracle/tablespace \
  -dit container-registry.oracle.com/database/free:latest-lite
