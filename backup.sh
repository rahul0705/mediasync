#!/bin/bash

FLOCK=/usr/bin/flock
RSYNC=/usr/bin/rsync
SSH=/usr/bin/ssh
PING=/usr/bin/ping
DATE=/usr/bin/date
SRC=$1
DEST=$2
RLFILE="$HOME/scripts/.read_lock_file"
WLFILE="$HOME/scripts/.write_lock_file"

CACHE="$HOME/recent"

NETLOG="$HOME/logs/network.log"
PUSHLOG="$HOME/logs/push.log"
NAMELOG="$HOME/logs/rename.log"

usage(){
    echo "Usage: ./script.sh source server:destintion"
    echo
    echo "source: must be full path"
    echo -e "\texample: /home/<user>/backupdir/"
    echo
    echo "server must be a full domain name"
    echo -e "\texample: test.example.com"
    echo
    echo "destination: must be full path"
    echo -e "\texample: /home/<user>/backup/"
}

clean(){
    rm "$HOME/logs/*"
}

isServerUp(){
    server=`echo $DEST | cut -d: -f1`
    netcheck=`$PING -c1 $server 2>&1 | grep unknown`

    echo `$DATE` >> "$NETLOG"
    if [ ! "$netcheck" = "" ]; then
        echo "Network down"  >> "$NETLOG"
        return 0;
    else
        echo "Network up"  >> "$NETLOG"
        return 1;
    fi
}

backup(){
    $FLOCK -n $RLFILE -c "$RSYNC --recursive --partial --perms --times --group --owner --verbose --compress --log-file="$PUSHLOG" --remove-source-files --exclude=".*" $SRC $DEST"
}

recentCache(){
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

change(){
    echo `date` >> $NAMELOG
    
    #lowercase
    echo `rename -v y/A-Z/a-z/ $SRC/*` >> $NAMELOG

    #get rid of Scene group
    echo `rename -v s/\-.*\.\(\[a-z\]\{3\}\)/\.\\$1/ $SRC/*` >> $NAMELOG

    #find all files in SRC exclude rename.sh
    files=`find $SRC -maxdepth 1 -type f \( ! -iname ".*" \) | grep -v rename.sh`

    for original_file in $files
    do
        #get rid of SRC in string
        #file=`echo $original_file | sed -e s/$SRC\///`
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
                echo "CREATED $SRC/movies FOLDER" >> $NAMELOG
            fi

            #move file into $SRC/movies
            echo `mv -v $original_file $SRC/movies` >> $NAMELOG

            #TV SHOW
        else
            #get show name
            showname=`echo $file | sed -re 's/\.s[0-9]+e[0-9]+.*$//'`

            #check if $SRC/tv exists if not make it
            if [ ! -d "$SRC/tv" ]
            then
                mkdir $SRC/tv
                echo "CREATED $SRC/tv FOLDER" >> $NAMELOG
            fi

            #check if $SRC/tv/$showname exists if not make it
            if [ ! -d "$SRC/tv/$showname" ]
            then
                mkdir $SRC/tv/$showname
                echo "CREATED $SRC/tv/$showname FOLDER" >> $NAMELOG
            fi

            #move file to $SRC/tv/$showname
            echo `mv -v $original_file $SRC/tv/$showname` >> $NAMELOG
        fi
    done 
}
