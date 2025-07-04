#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"


mkdir -p $LOGS_FOLDER 

echo "script started at $(date)" | tee -a $LOG_FILE

#check if the user has the root access or not

USER_ID=$(id -u)

if [ $USER_ID -ne 0 ]
then
    echo "${R}ERROR:You need Root access to run this script ${N}" | tee -a $LOG_FILE
    exit 90
else
    echo "${G}You are running the script with the root access ${N}" | tee -a $LOG_FILE
fi

#Validate function tells us if the command is successful or not

Validate(){
    if [ $1 -ne 0 ]
    then
        echo "$2 is a${G} success ${N}" | tee -a $LOG_FILE
    else
        echo "$2 is a${R} Failure ${N}" | tee -a $LOG_FILE
        exit 90
    fi
}


cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE

Validate $? "Copying the mongo repo"

dnf install monogdb-org -y &>> $LOG_FILE

Validate $? "installing mongodb"

systemctl enable mongod &>> $LOG_FILE

Validate $? "Enabing mongodb"

systemctl start mongod &>> $LOG_FILE

Validate $? "Starting mongodb"

sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

Validate $? "Giving access to the remote connections"

systemctl restart mongod &>> $LOG_FILE

Validate $? "Restarting Mongodb"






