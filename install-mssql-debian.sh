#!/bin/bash
# curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/install-mssql-debian.sh | bash
#

rm -rf /opt/sqlserver
mkdir -p /opt/sqlserver/var/opt/mssql
chmod -R 777 /opt/sqlserver

docker run \
  -e 'ACCEPT_EULA=Y' \
  -e 'SA_PASSWORD=Axway123!' \
  -p 1433:1433 \
  --name SQLserver \
  --mount type=bind,source=/tmp,target=/tmp/host \
  --mount type=bind,source=/opt/sqlserver/var/opt/mssql,target=/var/opt/mssql \
  -d mcr.microsoft.com/mssql/server:2019-latest