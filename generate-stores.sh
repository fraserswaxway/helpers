#!/bin/bash

# bash <(curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/install-oracle-debian.sh) -n sentinel -o create -d /opt/oracle -p 11521 -c changeit
# bash <(curl -L
#   https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/generate-stores.sh)
#   -n sentinel -o create -d /opt/oracle -p 11521 -c changeit -m


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

exit 0


# ==================
rm -f certificate.conf certificate.crt certificate.key certificate.p12 certificate.pem key.pem
short=`hostname -s`
full=`hostname -f`
ip=`hostname -I | cut -f1 -d' '`
cat > certificate.conf << EOF
default_bits = 1024
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
countryName = US
stateOrProvinceName = AZ
localityName = Phoenix
organizationName = Self-signed certificate
commonName = $short
[req_ext]
subjectAltName = @alt_names
[v3_req]
subjectAltName = @alt_names
[alt_names]
IP.1 = $ip
DNS.1 = $full
EOF
openssl req -x509 -newkey rsa:1024 -days 3650 -nodes -keyout certificate.key -out certificate.crt -config certificate.conf
openssl pkcs12 -export -in certificate.crt -inkey certificate.key -out certificate.p12 -passout pass:changeit -name $full
ln -s certificate.key key.pem
ln -s certificate.crt certificate.pem
chmod a+r *
# ==================
#openssl req -x509 -newkey rsa:512 -sha256 -days 3650 -nodes -keyout sentinel.key -out sentinel.crt -config sentinel.conf
#openssl pkcs12 -export -in sentinel.crt -inkey sentinel.key -out sentinel.p12 -name sl2csocust3812.pcloud.axway.int
/opt/monitoring/Java/linux-x86/jre17.00.16_64/bin/keytool -importkeystore -srckeystore certificate.p12 -srcstoretype pkcs12 -destkeystore sentinel.jks -alias sentinel
# changeit
# ==================
docker run --name javatemp --rm -it -v /tmp:/tmp/stuff eclipse-temurin:25 openssl
# ==================
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null | openssl x509 -outform PEM > certificate.pem
openssl s_client -connect integrator-8596432-admin.okta.com:443 -servername integrator-8596432-admin.okta.com </dev/null 2>/dev/null | openssl x509 -outform PEM > okta.pem
openssl x509 -in okta.pem -text -noout
# ==================

/opt/monitoring/Java/linux-x86/jre17.00.16_64/bin/keytool -importcert -alias sentinel -file certificate.crt -keystore truststore.jks -storepass changeit -keypass changeit -noprompt
/opt/monitoring/Java/linux-x86/jre17.00.16_64/bin/keytool -importcert -alias okta -file okta.pem -keystore truststore.jks -storepass changeit -keypass changeit -noprompt

  a. cd /opt/axway/certs
  b. /opt/monitoring/Java/linux-x86/jre17.00.16_64/bin/keytool -importcert -alias sentinel -file certificate.crt -keystore truststore.jks
       - .  Whenever prompted for a password use changeme
  c. /opt/monitoring/Java/linux-x86/jre17.00.16_64/bin/keytool -importcert -alias keycloak -file okta.crt -keystore truststore.jks
       - .  Whenever prompted for a password use changeme
# ==================


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