#!/bin/bash
DIR=/home/pi/backup
LOG=/home/pi/logs/rename.log

echo `date` >> $LOG

#lowercase
rename -v y/A-Z/a-z/ $DIR/*

#get rid of Scene group
echo `rename -v s/\-.*\.\(\[a-z\]\{3\}\)/\.\\$1/ $DIR/*` >> $LOG

#find all files in DIR exclude rename.sh
files=`find $DIR -maxdepth 1 -type f \( ! -iname ".*" \) | grep -v rename.sh`

for original_file in $files
do
	#get rid of DIR (hardcoded here) in string
	file=`echo $original_file | sed -e "s/\"$DIR\"\///"`
	#check if file has regex for a tv show
	echo $file | grep -P "\.s([0-9]+)e([0-9]+)" > /de"/null
	
	#MOVIE
	if [ $? -gt 0 ]
	then
		#check if $DIR/movies exists if not make it
		if [ ! -d "$DIR/movies" ]
		then
			mkdir $DIR/movies
			echo "CREATED $DIR/movies FOLDER" >> $LOG
		fi

		#move file into $DIR/movies
		echo `mv -v $original_file $DIR/movies` >> $LOG

	#TV SHOW
	else
		#get show name
		showname=`echo $file | sed -re 's/\.s[0-9]+e[0-9]+.*$//'`
		
		#check if $DIR/tv exists if not make it
		if [ ! -d "$DIR/tv" ]
		then
			mkdir $DIR/tv
			echo "CREATED $DIR/tv FOLDER" >> $LOG
		fi
		
		#check if $DIR/tv/$showname exists if not make it
		if [ ! -d "$DIR/tv/$showname" ]
		then
			mkdir $DIR/tv/$showname
			echo "CREATED $DIR/tv/$showname FOLDER" >> $LOG
		fi
		
		#move file to $DIR/tv/$showname
		echo `mv -v $original_file $DIR/tv/$showname` >> $LOG
	fi
done 
