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
SCRIPTS_DIR=$PWD # Define the directory where the scripts are located
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
    echo -e "$B Creating roboshop cart $N"
    useradd roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating roboshop cart"
else
    echo -e "$Y roboshop cart already exists,SKIPPING... $N"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating application directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
VALIDATE $? "Downloading cart application artifact"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changing to application directory"

rm -rf * &>>$LOGS_FILE 
VALIDATE $? "Cleaning application directory"
unzip /tmp/cart.zip &>>$LOGS_FILE
VALIDATE $? "Extracting cart application artifact"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changing to application directory"

npm install    &>>$LOGS_FILE
VALIDATE $? "Installing cart application dependencies"

cp $SCRIPTS_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart service file"

systemctl daemon-reload 
VALIDATE $? "Reloading systemd daemon"

systemctl enable cart 
VALIDATE $? "Enabling cart service"

systemctl restart cart &>>$LOGS_FILE
VALIDATE $? "Restarting cart service"