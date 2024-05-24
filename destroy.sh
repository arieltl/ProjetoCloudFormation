#!/bin/bash

# Check if stack name is provided
if [ -z "$1" ]
then
  echo "Please provide the stack name as a parameter."
  exit 1
fi

STACK_NAME=$1

# Delete the CloudFormation stack
aws cloudformation delete-stack --stack-name $STACK_NAME > /dev/null


# Delete the DynamoDB table
aws dynamodb delete-table --table-name Games > /dev/null