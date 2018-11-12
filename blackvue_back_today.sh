#!/bin/bash

# Init variables
DASHCAM_STORAGE="/mnt/PASSPORT/BlackVue-Back"
PREFIX="/Record/"

# IP address
DASHCAM_IP=192.168.8.125

export TODAY=`date +%Y%m%d`

# 192.168.8.120
echo `date '+%Y-%m-%d %H:%M:%S'`_blackvue_back
cd "$DASHCAM_STORAGE"

for file in `curl http://$DASHCAM_IP/blackvue_vod.cgi | sed 's/^n://' | sed 's/F.mp4//' | sed 's/R.mp4//' | sed 's/,s:1000000//' | sed $'s/\r//' | grep $TODAY`; do
	# Set VideoName
	VIDEONAME=${file#$PREFIX}
	
	# Front Video
	wget -c http://$DASHCAM_IP$file\F.mp4;
	if [ -f $VIDEONAME\F.mp4 ]; then
		sqlite3 /mnt/PASSPORT/tesla.db  "INSERT OR IGNORE INTO videos(VideoName,CameraSide) VALUES('$VIDEONAME','B');"
	fi

	# Left Video
	wget -c http://$DASHCAM_IP$file\R.mp4;
	if [ -f $VIDEONAME\R.mp4 ]; then
		sqlite3 /mnt/PASSPORT/tesla.db  "INSERT OR IGNORE INTO videos(VideoName,CameraSide) VALUES('$VIDEONAME','R');"
	fi

	wget -nc http://$DASHCAM_IP$file\F.thm;
	wget -nc http://$DASHCAM_IP$file\R.thm;
	wget -nc http://$DASHCAM_IP$file.gps;
	wget -nc http://$DASHCAM_IP$file.3gf;
done