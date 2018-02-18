#!/bin/bash
input="$1"
output=""
 
len=${#input}
for (( i=$len-1; i>=0; i-- ))
do 
	output="$output${input:$i:1}"
done
 
echo "$output"
