#!/bin/bash

set -e 

failure(){
    echo "Failed at: $1 $2"
}

trap 'failure "${LINENO}" "${BASH_COMMAND}" ERR'

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER 

START_TIME=$(date +%s)

echo "script started at $(date)" | tee -a $LOG_FILE

#check if the user has the root access or not

USER_ID=$(id -u)

if [ $USER_ID -ne 0 ]
then
    echo -e "${R}ERROR:You need Root access to run this script ${N}" | tee -a $LOG_FILE
else
    echo -e "${G}You are running the script with the root access ${N}" | tee -a $LOG_FILE
fi



dnf module disable nodejs -y  &>> $LOG_FILE


dnf module enable nodejs:20 -y  &>> $LOG_FILE


dnf install nodejs -y   &>> $LOG_FILE


id roboshop_user  &>> $LOG_FILE

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop_user  &>> $LOG_FILE

else
    echo -e "${Y}User has already been created ${N}" | tee -a $LOG_FILE
fi

mkdir -p /app



curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>> $LOG_FILE




cd /app

rm -rf * 

unzip /tmp/user.zip &>> $LOG_FILE


npm install &>> $LOG_FILE

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>> $LOG_FILE



systemctl daemon-reload &>> $LOG_FILE

systemctl enable user &>> $LOG_FILE

systemctl start user &>> $LOG_FILE


END_TIME=$(date +%s)

TIME_TAKEN=$(($END_TIME-$START_TIME))

echo -e "Script execution completed successfully, ${Y}time taken : ${G}$TIME_TAKEN seconds $N" | tee -a $LOG_FILE






