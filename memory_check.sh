#!/bin/bash

while getopts ":c:w:e:" params; do
 case $params in
   c) CRITICAL_THRESHOLD=$OPTARG ;;
   w) WARNING_THRESHOLD=$OPTARG ;;
   e) EMAIL_ADDRESS=$OPTARG ;;
   \?) echo "Invalid option -$OPTARG" >&2
       echo "Usage: $(basename $0) [-c critical_threshold] [-w warning_threshold] [-e email_address]" ;;
   *) echo "Error in command line parsing" >&2
      exit 1 ;;
 esac
done

if [ -z "$CRITICAL_THRESHOLD" ] || [ -z "$WARNING_THRESHOLD" ] || [ -z "$EMAIL_ADDRESS" ]; then
 echo "Missing required parameters" >&2
 echo "Usage: $(basename $0) [-c critical_threshold] [-w warning_threshold] [-e email_address]"
 exit 1
fi

if [ $WARNING_THRESHOLD -ge $CRITICAL_THRESHOLD ]; then
 echo "Critical threshold must be greater than warning threshold"
 echo "Usage: $(basename $0) [-c critical_threshold] [-w warning_threshold] [-e email_address]"
 exit 1
fi

MEMORY_USAGE=$(free | awk 'NR==2{ printf "%.2f", $3*100/$2 }')

if (( $(echo "$MEMORY_USAGE >= $CRITICAL_THRESHOLD" | bc -l) )); then
 echo "CRITICAL - Memory usage is ${MEMORY_USAGE}%"
 TOP_PROCESSES=$(ps aux --sort=-%mem | awk 'NR<=11{print $2,$4,$11}' | sed '1 i\PID %MEM COMMAND')
 EMAIL_SUBJECT="$CURRENT_DATE_TIME memory check - critical"
 EMAIL_BODY="The used memory is currently $MEMORY_USAGE bytes, which is greater than or equal to the critical threshold of $CRITICAL_THRESHOLD bytes. Here are the top 10 processes that use a lot of memory:\n\n$TOP_PROCESSES"

 if [ ! -z "$EMAIL_ADDRESS" ]; then
   echo "Sending email to $EMAIL_ADDRESS"
   echo -e "$EMAIL_BODY" | mail -s "Memory Usage Alert" $EMAIL_SUBJECT $EMAIL_ADDRESS
 fi
 exit 2
fi

if (( $(echo "$MEMORY_USAGE >= $WARNING_THRESHOLD" | bc -l) )); then
 echo "WARNING - Memory usage is ${MEMORY_USAGE}%"
 exit 1
fi

echo "OK - Memory usage is ${MEMORY_USAGE}%"
exit 0