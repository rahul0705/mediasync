#!/bin/bash

FLOCK=/usr/bin/flock
RSYNC=/usr/bin/rsync
INOTIFYWAIT=/usr/bin/inotifywait
RLFILE=var/run/mediasync.lock
LOG=/var/log/mediasync.log

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

watchMedia(){
	echo "$SRC"
	$INOTIFYWAIT -m -e close_write "$WATCHSRC" |
		while read dir event file
		do
			logger -s -t mediasync "$file has matched $event in $dir" 2>> $LOG
			mediaToSend=$file
			if [ $renameFlag ]
			then
				mediaToSend=$(renameMedia $file)
			fi
			sendMedia $mediaToSend
			cleanMedia $mediaToSend
		done
}

renameMedia(){
    #lowercase
    original_file=$WATCHSRC/$1
    echo $original_file | grep [A-Z] > /dev/null
    if [ $? -eq 0 ]
    then
        original_file=`rename -v y/A-Z/a-z/ $original_file`
        logger -s -t mediasync "$original_file" 2>> $LOG
        original_file=`echo $original_file | cut -d' ' -f4`
    fi

    #get rid of Scene group
    echo $original_file | grep -P '\-.*?\.[a-z|0-9]{3}$' > /dev/null
    if [ $? -eq 0 ]
    then
        original_file=`rename -v 's/(?:\-.*?)(\.[a-z|0-9]{3}$)/$1/' $original_file`
        logger -s -t mediasync "$original_file" 2>> $LOG
        original_file=`echo $original_file | cut -d' ' -f4`
    fi

    file=`basename $original_file`

    ret=$file	

    #check if file has regex for a tv show
    echo $file | grep -P "\.s([0-9]+).?e([0-9]+)" > /dev/null

    #MOVIE
    if [ $? -gt 0 ]
    then
        #check if $SRC/movies exists if not make it
        if [ ! -d "$SRC/movies" ]
        then
            mkdir $SRC/movies
            logger -s -t mediasync "CREATED $SRC/movies FOLDER" 2>> $LOG
        fi

        #move file into $SRC/movies
        logger -s -t mediasync "`mv -v $original_file $SRC/movies`" 2>> $LOG

        ret="movies/$file"

        #TV SHOW
    else
        #get show name
        showname=`echo $file | sed -re 's/\.s[0-9]+.?e[0-9]+.*$//'`

        #check if $SRC/tv exists if not make it
        if [ ! -d "$SRC/tv" ]
        then
            mkdir $SRC/tv
            logger -s -t mediasync "CREATED $SRC/tv FOLDER" 2>> $LOG
        fi

        #check if $SRC/tv/$showname exists if not make it
        if [ ! -d "$SRC/tv/$showname" ]
        then
            mkdir $SRC/tv/$showname
            logger -s -t mediasync "CREATED $SRC/tv/$showname FOLDER" 2>> $LOG
        fi

        #move file to $SRC/tv/$showname
        logger -s -t mediasync "`mv -v $original_file $SRC/tv/$showname`" 2>> $LOG


        ret="tv/$showname/$file"
    fi
    #done
    echo $ret
}

sendMedia(){
    logger -s -t mediasync "SENDING $SRC/$1 --> $DEST/$1" 2>> $LOG
    $FLOCK -n $RLFILE -c "$RSYNC --quiet --recursive --partial --perms --times --group --owner --verbose --compress --log-file="$LOG" --remove-source-files --include="$1" --include="*/" --exclude="*" $SRC $DEST"
}

cleanMedia(){
    dir=`dirname $SRC/$1`
    while [ $dir/ != $SRC ]
    do
        rmdir $dir
        logger -s -t mediasync "REMOVED $dir" 2>> $LOG
        dir=`dirname $dir`
    done
}

main(){
    ARGS=$(getopt -o hr -l "help,rename" -n "mediasync.sh" -- "$@");

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
    WATCHSRC=$1
    SRC=$1/.mediasync/
    DEST=$2
    mkdir -p $SRC
    watchMedia $renameFlag
}

on_end(){
    logger -s -t mediasync "mediasync is terminating..." 2>> $LOG
    rm -rf $SRC
    kill $(jobs -p)
    logger -s -t mediasync "mediasync is terminated" 2>> $LOG
    exit 0
}

main "$@"

trap 'on_end' EXIT
trap 'on_end' SIGHUP
trap 'on_end' SIGINT
trap 'on_end' SIGQUIT
trap 'on_end' SIGKILL
trap 'on_end' SIGTERM
