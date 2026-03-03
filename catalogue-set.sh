#!/bin/bash

set -euo pipefail # Exit immediately if a command exits with a non-zero status, treat unset variables as an error, and return the exit status of the last command in the pipeline that failed

trap 'echo "Error occurred at line $LINENO while executing: $BASH_COMMAND"' ERR # Trap any error and print the line number and command that caused the error

USERID=$(id -u)
R='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
B='\033[0;34m'
N='\033[0m' # No Color

LOGS_FOLDER="/var/log/shell-roboshop" # Define the logs folder path
SCRIPT_NAME=$(echo $0 | cut -d "." -f1) # Define the logs file name based on the script name
LOGS_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # Define the full path to the logs file
MONGODB_HOST="mongodb.srini.store" # Define the MongoDB host address
SCRIPTS_DIR=$PWD # Define the directory where the scripts are located
mkdir -p $LOGS_FOLDER # Create the logs folder if it doesn't exist

echo "$(date): Starting the script execution..." | tee -a $LOGS_FILE # Log the start of the script execution

if [ $USERID -eq 0 ]; then
    echo -e "$B I am root user $N"
    else 
    echo -e "$R error:: you are not root user, please run this script as root user $N"
    exit 1
fi


#nodejs installation
dnf module disable nodejs -y &>>$LOGS_FILE
dnf module enable nodejs:20 -y &>>$LOGS_FILE
dnf install nodejs -y &>>$LOGS_FILE

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    echo -e "$B Creating roboshop user $N"
    useradd roboshop &>>$LOGS_FILE
else
    echo -e "$Y roboshop user already exists,SKIPPING... $N"
fi

mkdir -p /app &>>$LOGS_FILE
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 

cd /app &>>$LOGS_FILE
rm -rf * &>>$LOGS_FILE 

unzip /tmp/catalogue.zip &>>$LOGS_FILE
dgdfjkhfheofhoi

cd /app &>>$LOGS_FILE

npm install    &>>$LOGS_FILE

cp $SCRIPTS_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload &>>$LOGS_FILE
systemctl enable catalogue &>>$LOGS_FILE
systemctl start catalogue &>>$LOGS_FILE

cp $SCRIPTS_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$LOGS_FILE

INDEX=$(mongosh mongodb.srini.store --quiet --eval    "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOGS_FILE

else
    echo -e "$Y catalogue database already exists,SKIPPING... $N"
fi
systemctl restart catalogue &>>$LOGS_FILE


