#!/bin/bash

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

mkdir -p $LOGS_FOLDER # Create the logs folder if it doesn't exist

echo "$(date): Starting the script execution..." | tee -a $LOGS_FILE # Log the start of the script execution

if [ $USERID -eq 0 ]; then
    echo -e "$B I am root user $N"
    else 
    echo -e "$R error:: you are not root user, please run this script as root user $N"
    exit 1
fi

VALIDATE(){ # function to validate the exit status of the last command
    if [ $1 -eq 0 ]; then
        echo -e "$G $2  successful $N" | tee -a $LOGS_FILE # Log the success message to the logs file
    else 
        echo -e "$R error:: $2  failed $N" | tee -a $LOGS_FILE # Log the error message to the logs file
        exit 1
    fi
}

#nodejs installation
dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling NodeJS module"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling NodeJS 20 module"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    echo -e "$B Creating roboshop user $N"
    useradd roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "$Y roboshop user already exists,SKIPPING... $N"
fi

mkdir -p /app 
VALIDATE $? "Creating application directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue application artifact"

cd /app 
unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Extracting catalogue application artifact"

cd /app 
npm install    &>>$LOGS_FILE
VALIDATE $? "Installing catalogue application dependencies"

vim catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload 
VALIDATE $? "Reloading systemd daemon"

systemctl enable catalogue 
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue
VALIDATE $? "Starting catalogue service"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB Shell"

mongosh --host $MONGODB_HOST </app/db/master-data.js
VALIDATE $? "Loading master data to MongoDB"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restarting MongoDB"

show dbs
VALIDATE $? "Showing databases in MongoDB"

use catalogue
VALIDATE $? "Switching to catalogue database in MongoDB"

show collections
VALIDATE $? "Showing collections in MongoDB"

db.products.find()
VALIDATE $? "Showing documents in products collection in MongoDB"