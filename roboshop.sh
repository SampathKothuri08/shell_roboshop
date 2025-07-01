#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-08c4689c508457947"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z04864553QUAPD26W0MEV"
DOMAIN_NAME="devopseng.shop"

for instance in ${INSTANCES[@]}
do 
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t2.micro \
        --security-group-ids $SG_ID \
        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=$instance}]' \
        --query "Instances[0].InstanceId" \
        --output text)

    if [ $instance != "frontend" ]
    then
        IP=$(instance_id=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text))
    else
        IP=$(instance_id=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text))
    fi
    echo "The IP address of $instance is $IP"
done 
