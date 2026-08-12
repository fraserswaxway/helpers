#!/bin/bash

# bash <(curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/axway-sentinel/install-sentinel-oracle-debian.sh)

#podman login docker.repository.axway.com --username <service account> --password <service account secret>
#podman pull docker.repository.axway.com/sentineleventrouter-docker-prod/3.0/eventrouter:3.0.20260302
#podman tag docker.repository.axway.com/sentineleventrouter-docker-prod/3.0/eventrouter:3.0.20260302 $(hostname -f | tr '[:upper:]' '[:lower:]')/library/eventrouter:3.0.20260302
#podman login --tls-verify=false $(hostname -f | tr '[:upper:]' '[:lower:]') --username admin --password Harbor12345
#podman push --tls-verify=false $(hostname -f | tr '[:upper:]' '[:lower:]')/library/eventrouter:3.0.20260302

#check

#https://dl8qxvt9zaqmi.cloudfront.net/filestore/da/dad999cc3443fb02ed586c9dfd02e34c98126dda?response-content-type=application%2Fzip&response-content-disposition=attachment%3Bfilename%3D%22Sentinel_4.2.0_Install_linux-x86-64_BN18540.zip%22&x-jf-traceId=d8844a897cb671088941643ba918ca17&X-Artifactory-repositoryKey=sentinel-generic-prod-ptx&X-Artifactory-projectKey=default&X-Artifactory-artifactPath=4.2.0%2FSentinel_4.2.0_Install_linux-x86-64_BN18540.zip&X-Artifactory-username=repositoryproduser%40axway.int&X-Artifactory-repoType=local&X-Artifactory-packageType=generic&X-Artifactory-originRepositoryKey=sentinel-generic-prod&X-Artifactory-originProjectKey=default&X-Artifactory-originRepoType=virtual&X-Artifactory-originPackageType=generic&Expires=1786197718&Signature=fWcovy9L0jWk0ZG741u1G4EF-~2pneAntG9dKi7HXU~XdHFnTqlac7Anh093jWM~Rg1rWZ3PcfpYk6PhEDXRxg-aEepurXZc-a2a3wLpl4r5n~KqmW8kQa3EpsKvsoHi-PAPA1nhRhdPs7~vCUSk6NZawH7rU3YuAD0bdJW~auXyaaZoO4l9RzW-mDtS-WoBnDX6rafTP0aiFyKReFtqq~zJImsJaGsvd-gUPUn58zlIwQzf4i3ucGonVo5~-I3mzx0a0YWINGjiK615SAr5fqCtpB~w3E6tEScPqtBhmjNCH0jv~Ig6vuNSO5Fu0rkVzNkR9-~X8fBUaiD-tvlskQ__&Key-Pair-Id=APKAJ6NHFWMVU3M6DPBA

# registry

# You can download the chart from Artifactory and from Webliv:Artifactory URL:  https://artifactory-ptx.ecd.axway.int:443/artifactory/sentinel-helm-release-ptx/Sentinel_HelmChart_linux-x86-64_4.2.0_SP37.tgz
#Webliv : Webliv

#docker login docker.repository.axway.com --username <client_id> --password <client_secret>
#docker pull docker.repository.axway.com/sentinel-docker-prod/4.2.0/sentinel:4.2.0-SP38

#read -s -p "Enter password: " my_var

if [ "$EUID" -e 0 ]; then
  echo -e "\n\nPlease NOT run as root\n"
  exit 1
fi

# path
# license
# database
# sed
# setup.sh –s <the absolute path to the installer Silent File>

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