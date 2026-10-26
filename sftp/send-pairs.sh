#!/usr/bin/env bash

# rm -rf
# bash <(curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/sftp/send-pairs.sh)

help=false
user=
password=
host=
port=
num=
backend=

findNext () {
  count=1
  while [ $count -le 5 ]
  do
    fnd=$(echo -e "cd backend\nls -1\nquit" | sshpass -p "$password" sftp -o StrictHostKeyChecking=no -P $port $user@$host 2>&1 | grep pdf)
    if ! [ -z "$fnd" ]; then
      backend=$(echo $fnd | cut -f1 -d'.')
      break
    fi

    sleep 2
    ((count++))
  done
}


info () {
  echo -e "\n...Configuration: "
  echo "user=$user"
  echo "password=$password"
  echo "host=$host"
  echo "port=$port"
  echo "num=$num"
  echo
}

command_help () {
  echo -e "Usage: -u <user> -c <password> -h <host> -p <port> -n <num>"
  echo -e "\nExamples:"
  echo    "  -u sftp -c sftp -h 192.168.1.236 -p 8022 -n 5"
}

echo -e "\n...Initializing\n"

command_help
shopt -s nocasematch

clean () {
  echo -e "cd incoming\nrm $dt*\nquit" | sshpass -p "$password" sftp -o StrictHostKeyChecking=no -P $port $user@$host 2>&1 > /dev/null 2>&1
  echo -e "cd issue\nrm *\nquit" | sshpass -p "$password" sftp -o StrictHostKeyChecking=no -P $port $user@$host 2>&1 > /dev/null 2>&1
  echo -e "cd backend\nrm *\nquit" | sshpass -p "$password" sftp -o StrictHostKeyChecking=no -P $port $user@$host 2>&1 > /dev/null 2>&1
  echo -e "cd lock\nrm *\nquit" | sshpass -p "$password" sftp -o StrictHostKeyChecking=no -P $port $user@$host 2>&1 > /dev/null 2>&1
}

leave () {
  local result=$1
  clean
  if [ -z "$result" ]; then
    echo -e "\n...[E] Missing result value for leave"
  fi

  echo -e "\n...Exit\n"
  exit $result
}

while getopts "u:c:h:p:n:" opt; do
  case $opt in
    u)
      user=$OPTARG
      ;;
    c)
      password=$OPTARG
      ;;
    h)
      host=$OPTARG
      ;;
    p)
      port=$OPTARG
      ;;
    n)
      num=$OPTARG
      ;;
    \?)
      help=true
      ;;
  esac
done

info

if [ -z "$user" ]; then
  echo -e "...[E] Invalid user specified"
  help=true
fi
if [ -z "$password" ]; then
  echo -e "...[E] Invalid password specified"
  help=true
fi
if [ -z "$host" ]; then
  echo -e "...[E] Invalid host specified"
  help=true
fi
if [ -z "$port" ]; then
  echo -e "...[E] Invalid port specified"
  help=true
fi
if ! [[ "$num" =~ ^-?[0-9]+$ ]]; then
  echo -e "...[E] Invalid number specified"
  help=true
fi

if [ "$help" == "true" ]; then
  leave 1
fi

clean
dt=$( echo $(($(date +%s%N) / 1000000)) )

echo ...Simulating uploads
for ((i=1; i<=$num; i++))
do
    theFile="${dt}_${i}"
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><important>sample data</important>" > $theFile.xml
    mv $theFile.xml $theFile.txt
    pandoc $theFile.txt -o $theFile.pdf
    mv $theFile.txt $theFile.xml
    echo ...$dt $i
    echo -e "cd incoming\nput $theFile.xml\nput $theFile.pdf\nquit" | sshpass -p "$password" sftp -o BatchMode=no -o StrictHostKeyChecking=accept-new -P $port $user@$host > /dev/null 2>&1
    rm -f $theFile.*
    sleep $(echo $(( RANDOM % 3 + 2 )))
done

echo
echo ...Simulating backend process
for ((i=1; i<=$num; i++))
do
  theFile="${dt}_${i}"
  # wait for files in backend folder
  doloop=1
  while [ $doloop == 1 ]
  do
    sleep 1
    findNext
    if ! [ -z "$backend" ]; then
      doloop=0
    else
      read -p "   Files not received yet. Try again? " response
      if [ ! -z "$response" ]; then
        case ${response:0:1} in
          n|x|q|f|0)
            leave 1
            ;;
        esac
      fi
    fi
  done
  echo "  " received a file pair $backend
  read -p "   simulate an issue? " response
  if [ ! -z "$response" ]; then
    case ${response:0:1} in
      y|t|1)
	      echo  "   generating an issue"
	      echo "{\"file\": \"$theFile\",\"description\": \"there was an issue with $theFile\"}" > $theFile.json
        echo -e "cd issue\nput $theFile.json\nquit" | sshpass -p "$password" sftp -o BatchMode=no -o StrictHostKeyChecking=accept-new -P $port $user@$host > /dev/null 2>&1
        rm -f $theFile.json
        ;;
    esac
  fi
  #Success
  read -p "   Press [Enter] to complete this file pair" value
  echo -e "cd backend\nrm *\nquit" | sshpass -p "$password" sftp -o StrictHostKeyChecking=no -P $port $user@$host 2>&1 > /dev/null 2>&1
  echo -e "cd lock\nrm *\nquit" | sshpass -p "$password" sftp -o StrictHostKeyChecking=no -P $port $user@$host 2>&1 > /dev/null 2>&1
  echo

   # for each
    #echo -e "cd backend\nls -1\nquit" | sshpass -p "$password" sftp -o StrictHostKeyChecking=no -P $port $user@$host 2>&1 | grep pdf

    #read -p "Type any value to quit or [Enter] to continue" value
    #if [ ! -z "$value" ]; then
    #  break
    #fi
    sleep 1
done

read -p "...Press [Enter] to proceed with cleanup..."
leave 0

