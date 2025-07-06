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


dnf install rabbitmq-server -y &>> $LOG_FILE

Validate $? "Installing rabbitmq server"

systemctl enable rabbitmq-server &>> $LOG_FILE

Validate $? "Enabling the rabbitmq sever"

systemctl start rabbitmq-server &>> $LOG_FILE

Validate $? "Starting rabbitmq"


echo -e "${Y}Enter the rabbitmq password to setup${N}" | tee -a $LOG_FILE
read -s RABBITMQ_PASSWD
rabbitmqctl add_user roboshop $RABBITMQ_PASSWD &>> $LOG_FILE

Validate $? "Creating a user in rabbitmq"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE

Validate $? "Setting permissions to the user"

END_TIME=$(date +%s)

TIME_TAKEN=$(($END_TIME-$START_TIME))

echo -e "Script execution completed successfully, ${Y}time taken : ${G}$TIME_TAKEN seconds $N" | tee -a $LOG_FILE

