#!/bin/bash

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_FILE=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_FILE.log"


SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER 

echo "script started at $(date)" | tee -a $LOG_FILE

#check if the user has the root access or not

USER_ID=$(id -u)

if [ $USER_ID -ne 0 ]
then
    echo -e "${R}ERROR:You need Root access to run this script ${N}" | tee -a $LOG_FILE
    exit 90
else
    echo -e "${G}You are running the script with the root access ${N}" | tee -a $LOG_FILE
fi

#Validate function tells us if the command is successful or not

Validate(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is a${G} success ${N}" | tee -a $LOG_FILE
    else
        echo -e "$2 is a${R} Failure ${N}" | tee -a $LOG_FILE
        exit 90
    fi
}



dnf module disable nginx -y &>> $LOG_FILE
Validate $? "Disabling nginx default version"

dnf module enable nginx:1.24 -y &>> $LOG_FILE
Validate $? "Enabling nginx version 1.24"

dnf install nginx -y &>> $LOG_FILE
Validate $? "Installing nginx"

systemctl enable nginx &>> $LOG_FILE

Validate $? "Enabling nginx"

systemctl start nginx &>> $LOG_FILE

Validate $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>> $LOG_FILE
Validate $? "Removing the existing content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> $LOG_FILE

Validate $? "Downloading the frontend code"

cd /usr/share/nginx/html 

unzip /tmp/frontend.zip &>> $LOG_FILE

Validate $? "Unzipping the frontend code"

rm -rf /etc/nginx/nginx.conf &>> $LOG_FILE
Validate $? "Removing the existing nginx configuration file"

cp /$SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf 

Validate $? "Copying the nginx configuration file to its default location"

systemctl restart nginx &>> $LOG_FILE

Validate $? "Restarting nginx"






