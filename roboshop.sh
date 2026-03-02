#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5" # Define the AMI ID for the EC2 instance
TYPE="t3.micro" # Define the instance type for the EC2 instance
SG_ID="sg-00c8683573ded1c4e" # Define the Security Group ID for the EC2 instance  
ZONE_ID="Z1003128U2OCSI7JICC9" # Define the Hosted Zone ID for Route 53
DOMAIN_NAME="srini.store" # Define the domain name for Route 53

for instance in "$@"
do
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$TYPE" \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID"

  if [ "$instance" != "frontend" ]; then
      IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' \
        --output text)
      RECORD_NAME="$instance.$DOMAIN_NAME"
  else
      IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
      RECORD_NAME="$DOMAIN_NAME"
  fi

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Comment\": \"Updating record set\",
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$RECORD_NAME\",
          \"Type\": \"A\",
          \"TTL\": 300,
          \"ResourceRecords\": [{
            \"Value\": \"$IP\"
          }]
        }
      }]
    }"

done