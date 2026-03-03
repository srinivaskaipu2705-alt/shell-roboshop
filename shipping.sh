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
MYSQL_HOST="mysql.srini.store" # Define the MySQL host address

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

dnf install maven -y &>>$LOGS_FILE
VALIDATE $? "Installing Maven"

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

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Downloading shipping application artifact"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changing to application directory"

rm -rf * &>>$LOGS_FILE 
VALIDATE $? "Cleaning application directory"

unzip /tmp/shipping.zip &>>$LOGS_FILE
VALIDATE $? "Extracting shipping application artifact"

cd /app &>>$LOGS_FILE
VALIDATE $? "Changing to application directory"

mvn clean package &>>$LOGS_FILE
VALIDATE $? "Building shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOGS_FILE
VALIDATE $? "Renaming shipping application jar file"

systemctl daemon-reload &>>$LOGS_FILE
VALIDATE $? "Reloading systemd daemon"

cp $SCRIPTS_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOGS_FILE
VALIDATE $? "Copying shipping systemd service file" 

systemctl enable shipping &>>$LOGS_FILE
VALIDATE $? "Enabling shipping service" 

systemctl start shipping &>>$LOGS_FILE
VALIDATE $? "Starting shipping service"

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "Installing MySQL client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "use cities" &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGS_FILE
else
    echo -e "$Y shipping data is already loaded SKIPPING... $N" | tee -a $LOGS_FILE
fi

systemctl restart shipping &>>$LOGS_FILE
VALIDATE $? "Restarting shipping service"

END_TIME=$(date +%s) # Record the end time of the script execution
EXECUTION_TIME=$(($END_TIME - $START_TIME)) # Calculate the execution time
echo "$(date): Script execution completed in $EXECUTION_TIME seconds." | tee -a $LOGS_FILE