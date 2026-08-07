#!/bin/bash
# curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/install-oracle-debian.sh | bash
# curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/install-oracle-debian.sh | bash -s -- -h

command=$0
directory=/opt/oracle
name=oracle
help=false
interactive=false
password=pzzwrd
port=1521

echo -e "\n...Initializing\n"

command_help () {
  echo -e "\nUsage: $command [-i] [-h] [-n <name>] [-d <directory>]"
  echo -e " -i interactive mode"
  echo -e " -d directory"
  echo -e " -n container name"
  echo -e " -h optional display this helpful message"
  echo -e "\nExamples:"
  echo -e "  $command -i"
  echo -e "  $command -n database -d /tmp/oracle\n"
}

info () {
  echo -e "\nConfiguration"
  echo -e "...directory=$directory"
  echo -e "...name=$name"
  echo -e "...port=$port"
  echo -e "\n"
}

leave () {
  echo -e "\n...Exit\n"
  exit 1
}



while getopts "hin:d:p:" opt; do
  case $opt in
    d)
      directory=$OPTARG
      ;;
    p)
      port=$OPTARG
      ;;
    n)
      name=$OPTARG
      ;;
    i)
      interactive=true
      ;;
    h)
      help=true
      ;;
    \?)
	  help=true
      ;;
  esac
done

if [ "$help" == "true" ]; then
  command_help
  leave
fi

response=help
while $interactive
do
  info
  echo "=====> Menu: "
  echo " n set name"
  echo " p set port"
  echo " d set directory"
  echo " r resume"
  read -p "Selection: " response

  case ${response:0:1} in
    r)
	  break
      ;;
    p)
      read -p "Port [$port]: " value
      if [ ! -z "$value" ]; then
        port=$value
      fi
      ;;
    d)
      read -p "Directory [$directory]: " value
      if [ ! -z "$value" ]; then
        directory=$value
      fi
      ;;
    n)
      read -p "Name [$name]: " value
      if [ ! -z "$value" ]; then
        name=$value
      fi
      ;;
    *)
      echo -e "\n...[E] Invalid request"
	  ;;
  esac
done


if [ -z "$directory" ]; then
  echo -e "...[E] Invalid directory specified"
  help=true
fi

if [ -z "$name" ]; then
  echo -e "...[E] Invalid name specified"
  help=true
fi

if [ "$help" == "true" ]; then
  info
  leave
fi

echo -e "\n...Deploying\n"

info

rm -rf $directory
mkdir -p $directory/oradata
mkdir -p $directory/tablespace
chmod -R 777 $directory

docker run --name $name --hostname $name \
  -p $port:1521 \
  -e ORACLE_PWD=$password \
  -v $directory/oradata:/opt/oracle/oradata \
  -v $directory/tablespace:/opt/oracle/tablespace \
  -dit container-registry.oracle.com/database/free:latest-lite

leave