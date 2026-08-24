#!/bin/bash

if [ $# -lt 2 ]
then
    echo  "Error: missing arguments"
    exit 1
fi

writefile=$1
writestr=$2

writepath=$(dirname "$writefile")
mkdir -p "$writepath"

if [ $? -ne 0 ]
then
   echo "Error: could not create directory"
   exit 1
fi

echo "$writestr" > "$writefile"
if [ $? -ne 0 ]
then 
   echo "Error: could not create file $writefile" 
   exit 1
fi

