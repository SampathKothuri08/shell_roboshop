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

dnf module disable nodejs -y  &>> $LOG_FILE

Validate $? "Disabling the default nodejs version" 

dnf module enable nodejs:20 -y  &>> $LOG_FILE

Validate $? "Enabling nodejs:20" 

dnf install nodejs -y   &>> $LOG_FILE

Validate $? "Installing nodejs"

id roboshop_cart  &>> $LOG_FILE

if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop_cart  &>> $LOG_FILE
    Validate $? "Creating a system user" &>> $LOG_FILE
else
    echo -e "${Y}User has already been created ${N}" | tee -a $LOG_FILE
fi

mkdir -p /app

Validate $? "Created an app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip  &>> $LOG_FILE

Validate $? "Downloaded the user code"


cd /app

rm -rf * 
Validate $? "Removing the exisiting code if there's any"

unzip /tmp/cart.zip &>> $LOG_FILE

Validate $? "Unzipping the user code in the app directory"

npm install &>> $LOG_FILE

Validate $? "Installing all the dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service 

Validate $? "copying the user service file to its location"

systemctl daemon-reload &>> $LOG_FILE

systemctl enable cart &>> $LOG_FILE

systemctl start cart &>> $LOG_FILE

Validate $? "Starting the user service"



END_TIME=$(date +%s)

TIME_TAKEN=$(($END_TIME-$START_TIME))

echo -e "Script execution completed successfully, ${Y}time taken : ${G}$TIME_TAKEN seconds $N" | tee -a $LOG_FILE







