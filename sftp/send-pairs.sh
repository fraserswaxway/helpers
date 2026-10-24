#!/usr/bin/env bash
dt=$( echo $(($(date +%s%N) / 1000000)) )
cnt=$(echo $(( RANDOM % 5 + 3 )))

rm -f ack.txt nack.txt
touch nack.txt

echo ...processing $dt $cnt
for ((i=1; i<=cnt; i++))
do
    theFile="${dt}_${i}"
    result="SUCCESS"
    if [ $((RANDOM % 5)) -eq 0 ]; then
      result="ISSUE"
      echo "$theFile" >> nack.txt
    fi
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><important><result>$result</result></important>" > $theFile.xml
    # echo "$theFile $result" | tee -a ack.txt
    echo "$theFile $result" >> ack.txt
    mv $theFile.xml $theFile.txt
    pandoc $theFile.txt -o $theFile.pdf
    mv $theFile.txt $theFile.xml
    # ls -ltr $theFile.*
    # sshpass -e sftp -P "$PORT" -o BatchMode=no -o StrictHostKeyChecking=accept-new "$USER@$HOST" <<EOF
    echo -e "cd incoming\nput $theFile.xml\nput $theFile.pdf\nquit" | sshpass -p "user1" sftp -o BatchMode=no -o StrictHostKeyChecking=accept-new -P 8022 user1@192.168.1.236 > /dev/null 2>&1
    rm -f $theFile.*
    sleep $(echo $(( RANDOM % 3 + 1 )))
done

#while IFS=' ' read -r fn result
#do
    # echo "file is $fn with a result of $result"
#    if [ $result == "SUCCESS" ]; then
#      touch $fn.success
#      echo -e "cd incoming\nput $fn.success\nquit" | sshpass -p "user1" sftp -o StrictHostKeyChecking=no -P 8022 user1@192.168.1.236 > /dev/null 2>&1
#    else
#      touch $fn.issue
#      echo -e "cd incoming\nput $fn.issue\nquit" | sshpass -p "user1" sftp -o StrictHostKeyChecking=no -P 8022 user1@192.168.1.236 > /dev/null 2>&1
#    fi
#    rm -f $fn.*
#done < ack.txt

#while IFS=' ' read -r fn
#do
#    read -u 3 -p "...Press [Enter] to resolve $fn"
#    touch $fn.success
#    echo -e "cd incoming\nput $fn.success\nquit" | sshpass -p "user1" sftp -o StrictHostKeyChecking=no -P 8022 user1@192.168.1.236 > /dev/null 2>&1
#    # | grep -vi "password"
#    rm -f $fn.*
#done 3<&0 < nack.txt


while IFS=' ' read -r fn result
do
    read -u 3 -p "...Press [Enter] to process $fn as $result"
    # lock processing.txt
    if [ $result == "SUCCESS" ]; then
      echo -e "cd lock\nrm processing.txt\nquit" | sshpass -p "user1" sftp -o StrictHostKeyChecking=no -P 8022 user1@192.168.1.236 > /dev/null 2>&1
    else
      touch $fn.txt
      echo -e "cd issue\nput $fn.txt\nquit" | sshpass -p "user1" sftp -o StrictHostKeyChecking=no -P 8022 user1@192.168.1.236 > /dev/null 2>&1
      read -u 3 -p "...Press [Enter] to resolve $fn as $result"
      echo -e "cd issue\nrm $fn.txt\nquit" | sshpass -p "user1" sftp -o StrictHostKeyChecking=no -P 8022 user1@192.168.1.236 > /dev/null 2>&1
      echo -e "cd lock\nrm processing.txt\nquit" | sshpass -p "user1" sftp -o StrictHostKeyChecking=no -P 8022 user1@192.168.1.236 > /dev/null 2>&1
    fi


    # | grep -vi "password"
    rm -f $fn.*
done 3<&0 < ack.txt

read -p "...Press [Enter] to proceed with cleanup..."

echo ...cleanup $dt $cnt
echo -e "cd incoming\nrm $dt*\nquit" | sshpass -p "user1" sftp -o StrictHostKeyChecking=no -P 8022 user1@192.168.1.236 2>&1 > /dev/null 2>&1

rm -f ack.txt nack.txt temp.txt
echo ...done
