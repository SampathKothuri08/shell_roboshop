#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

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

dnf module disable nodejs -y  &>> $LOG_FILE

Validate $? "Disabling the default nodejs version" 

dnf module enable nodejs:20 -y  &>> $LOG_FILE

Validate $? "Enabling nodejs:20" 

dnf install nodejs -y   &>> $LOG_FILE

Validate $? "Installing nodejs"

id roboshop  &>> $LOG_FILE

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>> $LOG_FILE
    Validate $? "Creating a system user"
else
    echo -e "${Y}User has already been created ${N}" | tee -a $LOG_FILE
fi

mkdir -p /app
Validate $? "Creating an app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>> $LOG_FILE

Validate $? "Downloading the catalogue code"

cd /app

rm -rf *

unzip /tmp/catalogue.zip  &>> $LOG_FILE

Validate $? "Unzipping the catalogue code in the app directory"

npm install  &>> $LOG_FILE

Validate $? "Installing all the dependencies"

cp /$SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemd daemon-reload  &>> $LOG_FILE
Validate $? "Reloaded the daemon"

systemctl enable catalogue  &>> $LOG_FILE
Validate $? "Enabling the catalogue service"


systemctl start catalogue   &>> $LOG_FILE

Validate $? "Starting the catalogue service"

cp /$SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y  &>> $LOG_FILE

Validate $? "Installing mongosh, the mongodb client"

STATUS=$(mongosh --host mongodb.devopseng.shop --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ STATUS -lt 0 ]
then 
    mongosh --host mongodb.devopseng.shop </app/db/master-data.js  &>> $LOG_FILE
    Validate $? "Loading the data into mongodb server"
else
    echo "${Y}Data is already loaded, skip it!${N}" | tee -a $LOG_FILE
fi




