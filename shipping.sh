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


dnf install maven -y &>> $LOG_FILE

Validate $? "Installing Maven"

id shipping &>> $LOG_FILE

if [ $? -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" shipping &>> $LOG_FILE
else
    echo -e "${Y}The user has already been created ${N}" | tee -a $LOG_FILE
fi


mkdir -p /app &>> $LOG_FILE

Validate $? "Created an app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOG_FILE

Validate $? "Downloading the shipping code"
cd /app

rm -rf *

Validate $? "Removing the exisiting code in the home directory"

unzip /tmp/shipping.zip &>> $LOG_FILE

Validate $? "Unzipping the shipping code"


mvn clean package &>> $LOG_FILE

Validate $? "Cleaning, compiling the java code and packaging into a jar file" 

mv target/shipping-1.0.jar shipping.jar 

Validate $? "moving the jar file to the app directory"



cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

Validate $? "Creating a service file and moving it to its default location"

systemctl daemon-reload &>> $LOG_FILE

systemctl enable shipping &>> $LOG_FILE

systemctl start shipping &>> $LOG_FILE

Validate $? "Starting shipping"

dnf install mysql -y &>> $LOG_FILE

Validate $? "Installing mysql"

echo -e "${Y}Enter Mysql root password ${N}" 

read -s MYSQL_ROOT_PASSWORD

mysql -h mysql.devopseng.shop -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE

if [ $? -eq 0 ]
then
    echo -e "${y}Data is already loaded into the mysql ${N}"
else
    mysql -h mysql.devopseng.shop -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>> $LOG_FILE

    mysql -h mysql.devopseng.shop -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>> $LOG_FILE

    mysql -h mysql.devopseng.shop -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>> $LOG_FILE

    Validate $? "loading the data into mysql"
fi


systemctl restart shipping &>> $LOG_FILE

Validate $? "Restarting shipping"

END_TIME=$(date +%s)

TIME_TAKEN=$(($END_TIME-$START_TIME))

echo -e "Script execution completed successfully, ${Y}time taken : ${G}$TIME_TAKEN seconds $N" | tee -a $LOG_FILE



