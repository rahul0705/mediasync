#!/bin/bash
FLOCK=/usr/bin/flock
RLFILE=/home/pi/scripts/.read_lock_file
WLFILE=/home/pi/scripts/.write_lock_file
RSYNC=/usr/bin/rsync
SSH=/usr/bin/ssh

$FLOCK -n $RLFILE -c "$RSYNC -ravz --log-file=/home/pi/logs/backup.log --remove-source-files --exclude=".*" -e "$SSH" buu:/home/rahul/videos/Scene/ /home/pi/backup/"
$FLOCK -n $WLFILE -c "rm -r /home/pi/recent/"
$FLOCK -n $WLFILE -c "mkdir /home/pi/recent/"
files=`ls -t $(find /home/pi/backup/ -type f) | head -n 50`
for original_file in $files 
do
	file=`echo $original_file | sed -e 's/\/home\/pi\/backup\///'`
	directory="$(dirname "$file")"
	filename="$(basename "$file")"
	if [ ! -d "/home/pi/recent/$directory" ]
	then
		$FLOCK -n $WLFILE -c "mkdir -p /home/pi/recent/$directory"
	fi
	$FLOCK -n $WLFILE -c "ln -s $original_file /home/pi/recent/$directory/$filename"
done

$FLOCK -n $WLFILE -c "$RSYNC -PravzL --delete --log-file=/home/pi/logs/push.log /home/pi/recent/ duo:/home/pi/backup/"
$FLOCK -n $WLFILE -c "rm -r /home/pi/recent/"
