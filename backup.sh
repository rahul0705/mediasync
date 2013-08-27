#!/bin/bash

FLOCK=/usr/bin/flock
RSYNC=/usr/bin/rsync
SSH=/usr/bin/ssh
PING=/usr/bin/ping
DATE=/usr/bin/date
RLFILE="$HOME/scripts/.rsync_lock_file"
WLFILE="$HOME/scripts/.write_lock_file"

CACHE="$HOME/recent"

LOG="/var/log/mediaSync.log"

usage(){
    echo "Usage: ./script.sh [-hr] source [server:]destintion"
    echo
    echo "source: must be full path"
    echo -e "\texample: /home/<user>/backupdir/"
    echo
    echo "server must be a full domain name"
    echo -e "\texample: test.example.com"
    echo
    echo "destination: must be full path"
    echo -e "\texample: /home/<user>/backup/"
    echo
    echo "flags:"
    echo -e "\t-h, --help"
    echo -e "\t\tthis menu"
    echo -e "\t-r, --rename"
    echo -e "\t\trename all files in source to tv and movie folders located at destination"
    exit 0
}

clean(){
    rmdir $SRC/*
    echo "cleaned"
}

sendMedia(){
    $FLOCK -n $RLFILE -c "$RSYNC --recursive --partial --perms --times --group --owner --verbose --compress --log-file="$PUSHLOG" --remove-source-files --exclude=".*" $SRC $DEST"
}

recentCache(){
    $FLOCK -n $WLFILE -c "rm -r $CACHE"
    $FLOCK -n $WLFILE -c "mkdir $CACHE"

    files=`ls -t $(find $SRC -type f) | head -n 50`

    for original_file in $files 
    do
        file=`echo $original_file | sed -e 's/\/home\/pi\/backup\///'`
        directory="$(dirname "$file")"
        filename="$(basename "$file")"
        if [ ! -d "/home/pi/recent/$directory" ]
        then
            $FLOCK -n $WLFILE -c "mkdir -p $CACHE/$directory"
        fi
        $FLOCK -n $WLFILE -c "ln -s $original_file $CACHE/$directory/$filename"
    done

    $FLOCK -n $WLFILE -c "$RSYNC -PravzL --delete --log-file=$LOG $CACHE $DEST"
    $FLOCK -n $WLFILE -c "rm -r $CACHE"
}

renameMedia(){
    echo "hello"
    #lowercase
    logger -t mediaSync "`rename -v y/A-Z/a-z/ $SRC/*`"

    echo "hello"
    #get rid of Scene group
    logger -s -t mediaSync "`rename -v s/\-.*.\.\(\[a-z\|0-9\]\{3\}$\)/\.\$1/ $SRC/*`"

    #find all files in SRC
    files=`find $SRC -maxdepth 1 -type f \( ! -iname ".*" \)`

    for original_file in $files
    do
        #get rid of SRC in string
        file=`basename $original_file`
	
	#check if file has regex for a tv show
        echo $file | grep -P "\.s([0-9]+)e([0-9]+)" > /dev/null

        #MOVIE
        if [ $? -gt 0 ]
        then
            #check if $SRC/movies exists if not make it
            if [ ! -d "$SRC/movies" ]
            then
                mkdir $SRC/movies
                logger -s -t mediaSync "CREATED $SRC/movies FOLDER"
            fi

            #move file into $SRC/movies
            logger -s -t mediaSync "`mv -v $original_file $SRC/movies`"

            #TV SHOW
        else
            #get show name
            showname=`echo $file | sed -re 's/\.s[0-9]+e[0-9]+.*$//'`

            #check if $SRC/tv exists if not make it
            if [ ! -d "$SRC/tv" ]
            then
                mkdir $SRC/tv
                logger -s -t mediaSync "CREATED $SRC/tv FOLDER"
            fi

            #check if $SRC/tv/$showname exists if not make it
            if [ ! -d "$SRC/tv/$showname" ]
            then
                mkdir $SRC/tv/$showname
                logger -s -t mediaSync "CREATED $SRC/tv/$showname FOLDER"
            fi

            #move file to $SRC/tv/$showname
            logger -s -t mediaSync "`mv -v $original_file $SRC/tv/$showname`"
        fi
    done
}

watchMedia(){
	echo "$SRC"
	inotifywait -m -e close_write "$SRC" |
		while read dir event file
		do
			echo "$dir $event $file"
			if [ $renameFlag ]
			then
				renameMedia $file
			fi
			sendMedia
			clean
		done
}

main(){
	ARGS=$(getopt -o hr -l "help,rename" -n "mediaSync.sh" -- "$@");

	#Bad arguments
	if [ $? -ne 0 ]
	then
		exit 1
	fi

	eval set -- "$ARGS";

	while true
	do
  		case "$1" in
    		-h|--help)
      			shift;
      			usage;
      			;;
    		-r|--rename)
      			shift;
      			renameFlag=true;
      			;;
    		--)
      			shift;
      			break;
      			;;
		esac
	done
	SRC=$1
	DEST=$2
	watchMedia $renameFlag
}

main "$@"
