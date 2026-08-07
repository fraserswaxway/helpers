#!/bin/bash

if [ "$EUID" -e 0 ]; then
  echo -e "\n\nPlease NOT run as root\n"
  exit 1
fi

exit 0

image=container-registry.oracle.com/database/free:latest-lite
directory=~/oracle
name=free
help=false
interactive=false
password=pzzwrd
port=1521
operation=create
shopt -s nocasematch

echo -e "\n...Initializing\n"

command_help () {
  info
  echo -e "\nUsage: [-m] [-i <image>] [-h] [-n <name>] [-d <directory>] [-c <credential>]"
  echo -e " -m menu mode"
  echo -e " -o create|remove operation (create is default)"
  echo -e " -i image name"
  echo -e " -d directory"
  echo -e " -n container name"
  echo -e " -h optional display this helpful message"
  echo -e "\nExamples:"
  echo -e "  -i"
  echo -e "  -n free -d /tmp/oracle"
  echo -e "  -n free -o create -d /tmp/oracle -p 11521"
  echo -e "  -n free -o remove -d /tmp/oracle"
  echo -e "  -m"
  echo -e "\n"
}

info () {
  echo -e "\n=====> Current configuration: "
  echo -e "...operation=$operation"
  echo -e "...directory=$directory/$name"
  echo -e "...password=$password"
  echo -e "...USER=SYSTEM"
  echo -e "...SID=FREE"
  echo -e "...name=$name"
  echo -e "...port=$port"
  echo -e "...image=$image"
}

leave () {
 local result=$1
  if [ -z "$result" ]; then
    echo -e "\n...[E] Missing result value for leave"
  fi

  echo -e "\n...Exit\n"
  exit $result
}


while getopts "mhin:d:p:o:c:" opt; do
  case $opt in
    c)
      password=$OPTARG
      ;;
    d)
      directory=$OPTARG
      ;;
    o)
      operation=$OPTARG
      ;;
    p)
      port=$OPTARG
      ;;
    n)
      name=$OPTARG
      ;;
    m)
      interactive=true
      ;;
    i)
      image=$OPTARG
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
  leave 1
fi

response=help
while $interactive
do
  info
  echo -e "\n=====> Menu: "
  echo " n set name"
  echo " o set operation"
  echo " c set credential (password)"
  echo " p set port"
  echo " d set directory"
  echo " r resume"
  echo " q|x|b exit"
  read -p "Selection: " response

  case ${response:0:1} in
    x|q|b)
	  leave 0
      ;;
    r)
	  break
      ;;
    c)
      read -p "Credential (password) [$password]: " value
      if [ ! -z "$value" ]; then
        password=$value
      fi
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
    o)
      read -p "Operation [$operation] (create|remove): " value
      if [ ! -z "$value" ]; then
        operation=$value
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

if [ -z "$operation" ]; then
  echo -e "...[E] Invalid operation specified"
  help=true
fi

if [ -z "$password" ]; then
  echo -e "...[E] Invalid password specified"
  help=true
fi

if [[ ! "$operation" == [cr]* ]]; then
  echo -e "...[E] Invalid operation specified"
  help=true
fi

if [ "$help" == "true" ]; then
  info
  leave 1
fi

info

echo -e "\n"

if [ "${operation:0:1}" == "r" ]; then
  echo -e "\n...Remove\n"
  docker stop $name
  docker rm -f $name
  docker rmi -f container-registry.oracle.com/database/free:latest-lite
  rm -rf $directory/$name
fi

if [ "${operation:0:1}" == "c" ]; then
  echo -e "\n...Create\n"
  mkdir -p $directory/$name/oradata
  mkdir -p $directory/$name/tablespace
  chmod -R 777 $directory
  docker run --name $name --hostname $name \
    -p $port:1521 \
    -e ORACLE_PWD=$password \
    -v $directory/$name/oradata:/opt/oracle/oradata \
    -v $directory/$name/tablespace:/opt/oracle/tablespace \
    -dit $image
fi

leave 0