#!/bin/bash

# Check if URL is provided
if [ -z "$1" ]
then
  echo "Please provide the URL as a parameter."
  exit 1
fi

url=$1

# Check if number of iterations is provided, if not default to 20
iterations=${2:-20}

for i in $(seq 1 $iterations); do
  (curl -o /dev/null -s -w "%{http_code}\n" "$url" &) 
done
