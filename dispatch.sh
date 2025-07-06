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


dnf install golang -y &>> $LOG_FILE

Validate $? "Installing golong" 

id dispatch &>> LOG_FILE


if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "dispatch service" dispatch &>> LOG_FILE

    Validate $? "Creating a system user"
else
    echo -e "${Y}System user has already been created ${N}" | tee -a $LOG_FILE
fi


mkdir /app &>> $LOG_FILE

Validate $? "Creating an app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>> $LOG_FILE

cd /app 

rm -rf * &>> $LOG_FILE
Validate $? "Removing the existing code in the home directory"

unzip /tmp/dispatch.zip &>> $LOG_FILE
Validate $? "Unzipping the payment code in the home directory"

go mod init dispatch &>> $LOG_FILE

Validate $? "Initiating a new go module named dispatch"

go get &>> $LOG_FILE

Validate $? "Installing all required dependencies"

go build &>> $LOG_FILE

Validate $? "Compiling the code"


cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>> $LOG_FILE

Validate $? "Copying the dispatch service file to its right location"

systemctl daemon-reload &>> $LOG_FILE


systemctl enable dispatch &>> $LOG_FILE

systemctl start dispatch &>> $LOG_FILE

Validate $? "Starting dispatch"


END_TIME=$(date +%s)

TIME_TAKEN=$(($END_TIME-$START_TIME))

echo -e "Script execution completed successfully, ${Y}time taken : ${G}$TIME_TAKEN seconds $N" | tee -a $LOG_FILE

