#!/bin/bash

FLOCK=/usr/bin/flock
RSYNC=/usr/bin/rsync
SSH=/usr/bin/ssh
PING=/usr/bin/ping
DATE=/usr/bin/date
RLFILE="$HOME/scripts/.read_lock_file"
WLFILE="$HOME/scripts/.write_lock_file"

SERVER="duo.rahulmohandas.com"

CACHE="$HOME/recent"

NETLOG="$HOME/logs/network.log"
PULLLOG="$HOME/logs/pull.log"
PUSHLOG="$HOME/logs/push.log"

usage(){
    echo "Usage: ./script.sh source destination server"
    echo
    echo "source: must be full path"
    echo -e "\texample: /home/<user>/backupdir/"
    echo
    echo "destination: must be full path"
    echo -e "\texample: /home/<user>/backup/"
    echo
    echo "server must be a full domain name"
    echo -e "\texample: test.example.com"
}

clean(){
    rm "$HOME/logs/*"
}

isServerUp(){
    netcheck=`$PING -c1 $SERVER 2>&1 | grep unknown`

    echo `$DATE` >> /home/pi/logs/network.log
    if [ ! "$netcheck" = "" ]; then
        echo "Network down"  >> "$NETLOG"
        return 0;
    else
        echo "Network up"  >> "$NETLOG"
        return 1;
    fi
}

backup(){
    $FLOCK -n $RLFILE -c "$RSYNC -ravz --log-file="$PULLLOG" --remove-source-files --exclude=".*" buu:/home/rahul/videos/Scene/ /home/pi/backup/"
    $FLOCK -n $WLFILE -c "rm -r $CACHE"
    $FLOCK -n $WLFILE -c "mkdir $CACHE"

    files=`ls -t $(find /home/pi/backup/ -type f) | head -n 50`

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

    $FLOCK -n $WLFILE -c "$RSYNC -PravzL --delete --log-file=$PUSHLOG $CACHE duo:/home/pi/backup/"
    $FLOCK -n $WLFILE -c "rm -r $CACHE"
}

rename(){

    DIR=/home/pi/backup
    LOG=/home/pi/logs/rename.log

    echo `date` >> $LOG

    #lowercase
    rename -v y/A-Z/a-z/ $DIR/*

    #get rid of Scene group
    echo `rename -v s/\-.*?\(\.\[^\.\]*\)\$/\$1/ $DIR/*` >> $LOG

    #find all files in DIR exclude rename.sh
    files=`find $DIR -maxdepth 1 -type f \( ! -iname ".*" \) | grep -v rename.sh`

    for original_file in $files
    do
        #get rid of DIR (hardcoded here) in string
        file=`echo $original_file | sed -e "s/\"$DIR\"\///"`
        #check if file has regex for a tv show
        echo $file | grep -P "\.s([0-9]+)e([0-9]+)" > /dev/null

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
}
usage;
