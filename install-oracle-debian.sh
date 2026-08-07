#!/bin/bash
# curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/install-oracle-debian.sh | bash
# curl -L https://raw.githubusercontent.com/fraserswaxway/helpers/refs/heads/main/install-oracle-debian.sh | bash -s -- -h

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
}

leave () {
  echo -e "\n...Exit\n"
  exit 1
}



while getopts "hin:b:f:t:" opt; do
  case $opt in
    d)
      directory=$OPTARG
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

# ===========================================================
#if ! (grep -q "mftops-dev" $profile_file && grep -q "mftops-test" $profile_file && grep -q "mftops-prod" $profile_file); then
#  error_profiles
#fi while [[ $count -lt 5 && $status == "active" ]]; do
# ===========================================================
response=help
while $interactive
do
  echo ""
  echo "=====> Menu: "
  echo " l list folder contents recursively"
  echo " s show bucket contents recursively"
  echo " u upload $file to folder (NOTE: local copy $file created then remove after upload)"
  echo " d download $file from folder (NOTE: local copy of $file is removed after download)"
  echo " g get an existing file (NOTES: a) at least one file must be found in the foloder b) local copy is removed after download)"
  echo " r remove $file from folder"
  echo " q|x quit or exit"
  read -p "Selection: " response

  case ${response:0:1} in
    x|q)
	  exit 0
      ;;
    l)
      echo -e "\n...Here is a recursive listing of the folder"
      run "aws --profile mftops-$level s3 ls s3://$bucket/$folder/ --recursive $nocerts"
      ;;
    r)
      echo -e "\n...Removing $file from folder"
      run "aws --profile mftops-$level s3 rm s3://$bucket/$folder/$file $nocerts"
      ;;
    n)
      if [ -z "$nocerts" ]; then
        nocerts=--no-verify
      else
       nocerts=
      fi
	  ;;
    f)
      read -p "Folder [$folder]): " value
      if [ ! -z "$value" ]; then
        folder=$value
      fi
      ;;
    b)
      read -p "Bucket [$bucket]: " value
      if [ ! -z "$value" ]; then
        bucket=$value
      fi
      ;;
    h)
      echo -e "\n...Environment=[$level] Bucket=[$bucket] Folder=[$folder] Trace=[$debug] NoVerify=[$nocerts]"
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
  command_help
  leave
fi

info

# leave

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