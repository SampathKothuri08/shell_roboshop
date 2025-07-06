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



dnf install python3 gcc python3-devel -y &>> LOG_FILE

Validate $? "Installing python"

id payment &>> LOG_FILE


if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "payment service" payment &>> LOG_FILE

    Validate $? "Creating a system user"
else
    echo -e "${Y}System user has already been created ${N}" | tee -a $LOG_FILE
fi

mkdir -p /app &>> LOG_FILE


Validate $? "Creating an app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>> LOG_FILE


Validate $? "Downloading the payment code"

cd /app 

rm -rf * &>> LOG_FILE


Validate $? "Removing the existing code in the home directory"

unzip /tmp/payment.zip &>> LOG_FILE


Validate $? "Unzipping the payment code in the home directory"

pip3 install -r requirements.txt &>> LOG_FILE


Validate $? "Installing dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>> LOG_FILE


Validate $? "Copying the payment service file to its right location"


systemctl daemon-reload &>> LOG_FILE


systemctl enable payment &>> LOG_FILE



systemctl start payment &>> LOG_FILE


Validate $? "Starting the payment"


END_TIME=$(date +%s)

TIME_TAKEN=$(($END_TIME-$START_TIME))

echo -e "Script execution completed successfully, ${Y}time taken : ${G}$TIME_TAKEN seconds $N" | tee -a $LOG_FILE

