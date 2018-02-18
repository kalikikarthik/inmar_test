input=$1

echo $input | grep "[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]" 1>&2 > /dev/null 
if [[ $? != 0 ]]
then

 echo ""Invalid Format"" 1>&2 
 exit 1; 

else
    
  echo " Vaild Format"
fi
