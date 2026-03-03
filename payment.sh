#!/bin/bash

USERID=$(id -u)
R='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
B='\033[0;34m'
N='\033[0m' # No Color

START_TIME=$(date +%s) # Record the start time of the script execution
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

dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
VALIDATE $? "Installing Python3 and dependencies"  

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    echo -e "$B Creating roboshop user $N"
    useradd roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "$Y roboshop user already exists,SKIPPING... $N"
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating application directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
VALIDATE $? "Downloading payment application artifact"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changing to application directory"

rm -rf * &>>$LOGS_FILE 
VALIDATE $? "Cleaning application directory"
unzip /tmp/payment.zip &>>$LOGS_FILE
VALIDATE $? "Extracting payment application artifact"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changing to application directory"

pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? "Installing Python dependencies"

cp $SCRIPTS_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGS_FILE
VALIDATE $? "Copying payment systemd service file"  

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable payment &>>$LOGS_FILE
VALIDATE $? "Enabling payment service"

systemctl start payment &>>$LOGS_FILE
VALIDATE $? "Starting payment service" 

END_TIME=$(date +%s) # Record the end time of the script execution
EXECUTION_TIME=$(($END_TIME - $START_TIME)) # Calculate the execution time
echo "$(date): Script execution completed in $EXECUTION_TIME seconds." | tee -a $LOGS_FILE