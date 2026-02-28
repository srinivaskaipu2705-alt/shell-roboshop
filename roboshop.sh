#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5" # Define the AMI ID for the EC2 instance
SG_ID="sg-00c8683573ded1c4e" # Define the Security Group ID for the EC2 instance  

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID "ResourceType=instance,Tags=[{Key=Name,value=$instance}]" --query 'Instances[0].InstanceId' --output text) # Launch an EC2 instance and capture the Instance ID

# get the private IP address of the launched instance
if [ $instance != "frontend" ]; then
    IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text) # Get the private IP address of the launched instance
    echo "The private IP address of the $instance instance is: $IP" # Print the private IP address of the launched instance
else
    IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text) # Get the public IP address of the launched instance
    echo "The public IP address of the $instance instance is: $IP" # Print the public IP address of the launched instance
fi
echo "$instance : $IP" >> /tmp/instance-ips.txt # Append the instance name and IP address to a file
done