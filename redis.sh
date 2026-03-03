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
        echo -e "$G $2  successful $N" | tee -a $LOGS_FILE
    else 
        echo -e "$R error:: $2  failed $N" | tee -a $LOGS_FILE
        exit 1
    fi
}

dnf module disable redis -y &>>$LOGS_FILE
VALIDATE $? "Disabling Redis module"

dnf module enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "Enabling Redis 7 module"

dnf install redis -y &>>$LOGS_FILE
VALIDATE $? "Installing Redis"

sed -i 's/127.0.0.1/0.0.0.0/g' /protected-mode/ c protcted-mode no /etc/redis/redis.conf &>>$LOGS_FILE

systemctl enable redis &>>$LOGS_FILE
VALIDATE $? "Enabling Redis"

systemctl start redis &>>$LOGS_FILE
VALIDATE $? "Starting Redis"