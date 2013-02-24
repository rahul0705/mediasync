#!/bin/bash
x=`ping -c1 google.com 2>&1 | grep unknown`
echo `date` >> /home/pi/logs/network.log
if [ ! "$x" = "" ]; then
	echo "Network down"  >> /home/pi/logs/network.log
else
	echo "Network up"  >> /home/pi/logs/network.log
fi
