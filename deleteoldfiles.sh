#!/bin/bash
#
############################################################################### 
# Author            :  Louwrentius
# Contact           : louwrentius@gmail.com
# Initial release   : August 2011
# Licence           : Simplified BSD License
############################################################################### 

VERSION=1.00

#
# Mounted volume to be monitored.
#
MOUNT="/home/pi/backup"
#
# Maximum threshold of volume used as an integer that represents a percentage:
# 95 = 95%.
#
MAX_USAGE="90"
#
# Failsafe mechansim. Delete a maxium of MAX_CYCLES files, raise an error after
# that. Prevents possible runaway script. Disable by choosing a high value.
#
MAX_CYCLES=10


show_header () {

    echo
    echo DELETE OLD FILES $VERSION
    echo

}

show_header

reset () {
    CYCLES=0
    OLDEST_FILE=""
    OLDEST_DATE=0
    ARCH=`uname`
}

reset

if [ -z "$MOUNT" ] || [ ! -e "$MOUNT" ] || [ ! -d "$MOUNT" ] || [ -z "$MAX_USAGE" ]
then
    echo "Usage: $0 <mountpoint> <threshold>"
    echo "Where threshold is a percentage."
    echo
    echo "Example: $0 /storage 90"
    echo "If disk usage of /storage exceeds 90% the oldest"
    echo "file(s) will be deleted until usage is below 90%."
    echo 
    echo "Wrong command line arguments or another error:"
    echo 
    echo "- Directory not provided as argument or"
    echo "- Directory does not exist or"
    echo "- Argument is not a directory or"
    echo "- no/wrong percentage supplied as argument."
    echo
    exit 1
fi

check_capacity () {

    USAGE=`df -h | grep "$MOUNT" | awk '{ print $5 }' | sed s/%//g`
    if [ ! "$?" == "0" ]    
    then
        echo "Error: mountpoint $MOUNT not found in df output."
        exit 1
    fi

    if [ -z "$USAGE" ]
    then
        echo "Didn't get usage information of $MOUNT"
        echo "Mountpoint does not exist or please remove trailing slash."
        exit 1
    fi

    if [ "$USAGE" -gt "$MAX_USAGE" ]
    then
        echo "Usage of $USAGE% exceeded limit of $MAX_USAGE percent."
        return 0
    else
        echo "Usage of $USAGE% is within limit of $MAX_USAGE percent."
        return 1
    fi
}

check_age () {

    FILE="$1"
    if [ "$ARCH" == "Linux" ]
    then
        FILE_DATE=`stat -c %Z "$FILE"`
    elif [ "$ARCH" == "Darwin" ]
    then
        FILE_DATE=`stat -f %Sm -t %s "$FILE"`
    else
        echo "Error: unsupported architecture."
        echo "Send a patch for the correct stat arguments for your architecture."
    fi
        
    NOW=`date +%s`
    AGE=$((NOW-FILE_DATE))
    if [ "$AGE" -gt "$OLDEST_DATE" ]
    then
        export OLDEST_DATE="$AGE"
        export OLDEST_FILE="$FILE"
    fi
}

process_file () {
    
    FILE="$1"

    #
    # Replace the following commands with wathever you want to do with 
    # this file. You can delete files but also move files or do something else.
    #
    echo `date` >> /home/pi/logs/delete.log
    echo "Deleting oldest file $FILE" >> /home/pi/logs/delete.log
    rm -f "$FILE"
}

while check_capacity
do
    if [ "$CYCLES" -gt "$MAX_CYCLES" ]
    then
        echo "Error: after $MAX_CYCLES deleted files still not enough free space."
        exit 1
    fi
    
    reset

    FILES=`find "$MOUNT" -type f`
    
    IFS=$'\n'
    for x in $FILES
    do
        check_age "$x"
    done

    if [ -e "$OLDEST_FILE" ]
    then
        #
        # Do something with file.
        #
        process_file "$OLDEST_FILE"
    else
        echo "Error: somehow, item $OLDEST_FILE disappeared."
    fi
    ((CYCLE++))
done
echo
