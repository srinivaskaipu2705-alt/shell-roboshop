#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5" # Define the AMI ID for the EC2 instance
SG_ID="sg-00c8683573ded1c4e" # Define the Security Group ID for the EC2 instance  
ZONE_ID="Z1003128U2OCSI7JICC9" # Define the Hosted Zone ID for Route 53
DOMAIN_NAME="srini.store" # Define the domain name for Route 53

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text) # Launch an EC2 instance and capture the Instance ID


# get the private IP address of the launched instance
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text) # Get the private IP address of the launched instance
        echo "The private IP address of the $instance instance is: $IP" # Print the private IP address of the launched instance
        RECORD_NAME="$instance.$DOMAIN_NAME" # Define the record name for Route 53
    else
        IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text) # Get the public IP address of the launched instance
        echo "The public IP address of the $instance instance is: $IP" # Print the public IP address of the launched instance
        RECORD_NAME="$DOMAIN_NAME" # Define the record name for Route 53
    fi
    echo "$instance : $IP" >> /tmp/instance-ips.txt # Append the instance name and IP address to a file



    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record set"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "' $RECORD_NAME '"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'" $IP "'"
            }]
        }
        }]
    }
    '
done