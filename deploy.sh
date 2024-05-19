#!/bin/bash
# Check if stack name is provided
if [ -z "$1" ]
then
  echo "Please provide the stack name as a parameter."
  exit 1
fi
STACK_NAME=$1
PARAMETERS=""
# Check if parameters are provided
if [ ! -z "$2" ]
then
  PARAMETERS="--parameters $2"
fi
# Create stack with IAM capabilities
aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://projeto.yaml --capabilities CAPABILITY_IAM $PARAMETERS > /dev/null
# Wait for stack to be created
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
# Get stack output
aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs'