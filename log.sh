#!/bin/bash
cd log
> test.txt

for i in `ls`
do 
cat $i |awk '$0 >= "Apr 27, 2015 8:00:00 PM" && $0 <= "Apr 30, 2015 8:00:00 PM"' |awk -F' '  '{ if ($7 == "severe") print }' > testfile.txt
echo -e "$i\t`cat testfile.txt|wc -l`\t`cat testfile.txt`" >> test.txt
done
