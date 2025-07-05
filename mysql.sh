#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"


mkdir -p $LOGS_FOLDER 
#space is important as they are two different entities
START_TIME=$(date +%s)
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

echo -e "${Y}Please enter root password to setup ${N}" | tee -a $LOG_FILE
read -s MYSQL_ROOT_PASSWORD

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


dnf install mysql-server -y  &>> $LOG_FILE

Validate $? "Installing mysql server"

 
systemctl enable mysqld &>> $LOG_FILE

Validate $? "Enabling mysql"

systemctl start mysqld &>> $LOG_FILE

Validate $? "Starting mysql"


mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD &>> $LOG_FILE

Validate $? "Setting Mysql root password"


END_TIME=$(date +%s)

TIME_TAKEN=$(($END_TIME - $START_TIME))

echo -e "Script has executed successfully, ${Y}time taken :${G}$TIME_TAKEN seconds. ${N}" | tee -a $LOG_FILE