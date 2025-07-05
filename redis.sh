#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"


mkdir -p $LOGS_FOLDER 
START_TIME=$(date+%s)
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

dnf module disable redis -y | tee -a $LOG_FILE

Validate $? "Disabling the default version for redis"

dnf module enable redis:7 -y | tee -a $LOG_FILE

Validate $? "Enabliing the redis version 7"

dnf install redis -y | tee -a $LOG_FILE

Validate $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf

Validate $? "Changing the redis configuration file"


systemctl enable redis | tee -a $LOG_FILE

Validate $? "Enabling redis"

systemctl start redis | tee -a $LOG_FILE

Validate $? "Starting redis"

END_TIME=$(date+%s)

TIME_TAKEN=$(($END_TIME-$START_TIME))

echo "Script execution completed successfully, ${Y}time taken : ${G}$TIME_TAKEN seconds $N" | tee -a $LOG_FILE



