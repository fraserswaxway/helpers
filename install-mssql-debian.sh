#!/bin/bash

rm -rf /opt/sqlserver
mkdir -p /opt/sqlserver
chmod -R 777 /opt/sqlserver

docker run \
  -e 'ACCEPT_EULA=Y' \
  -e 'SA_PASSWORD=Axway123!' \
  -p 1433:1433 \
  --name SQLserver \
  --mount type=bind,source=/tmp,target=/tmp/host \
  --mount type=bind,source=/axwaynfs/docker/mount/sqlserver/var/opt/mssql,target=/var/opt/mssql \
  -d mcr.microsoft.com/mssql/server:2019-latest