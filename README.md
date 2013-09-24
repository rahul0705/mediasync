mediasync
=========

Wrapper for rsync to send files from one server to another
(files will be deleted in orginating server).
Files can be renamed to match XBMC directory structures


Recommended to run in a screen session

Installation
------------

###Requirements

1. inotifywait

		sudo apt-get install inotify-tools

2. rsync

		sudo apt-get install rsync

3. rename

		built into debian/ubuntu
	
4. logrotate

		sudo apt-get install logrotate

###Install

	sudo make install

###Uninstall

	sudo make uninstall

Directories modified:
* /usr/local/bin
* /etc/logrotate.d/
* /var/log/
* /var/run/

Examples
--------

1. Send files that appear in directory /path/to/src/
to the path /path/to/dest on server (optional) (Files will be deleted in A):

		mediasync /path/to/src/ [server:]/path/to/dest

	It is required that you have SSH keys setup between src and dest servers since
	mediasync will open a connection to dest for every file that appears in src
	
2. Send files that appear in directory A to B (Files will be renamed to match XBMC directories):
	
		mediasync --rename /path/to/src/ [server:]/path/to/dest

	or

		mediasync -r /path/to/src/ [server:]/path/to/dest

	It is required that you have SSH keys setup between src and dest servers since
	mediasync will open a connection to dest for every file that appears in src

3. Help screen

		mediasync --help

	or

		mediasync -h

Bugs
----

* mediasync currently only has the capability of monitoring one directory and no sub-directories inside of it.
* Currently the only things that match a "TV" release would be something containing sXXeXX.
* Items that do not match "TV" releases will be defaulted into "Movies" releases.
