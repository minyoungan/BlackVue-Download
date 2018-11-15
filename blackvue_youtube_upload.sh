#!/bin/bash

# Init Variables
# File Location
dashcam_storage_front="/mnt/PASSPORT/BlackVue-Front"
dashcam_storage_back="/mnt/PASSPORT/BlackVue-Back"

# Youtube
youtube_description="Tesla, BlackVue"

# Date
today_datetime=$(date '+%Y-%m-%d %H:%M:%S')


# Get the latest event video
video=$(sqlite3 /mnt/PASSPORT/tesla.db -cmd ".timeout 5000" "SELECT VideoName,CameraSide FROM Videos AS v WHERE (VideoName LIKE strftime('%Y%m%d') || '%E' OR VideoName LIKE strftime('%Y%m%d','now','-1 day') || '%E') AND NOT EXISTS (SELECT 1 FROM uploads WHERE VideoName = v.VideoName AND CameraSide = v.CameraSide) ORDER BY VIDEONAME DESC LIMIT 1;")
video_mode="Event Mode"

if [[ -n "${video// /}" ]]; then
	# Event video found
	true
else
	# Event video not found
	video=$(sqlite3 /mnt/PASSPORT/tesla.db -cmd ".timeout 5000" "SELECT VideoName,CameraSide FROM Videos AS v WHERE (VideoName LIKE strftime('%Y%m%d') || '%P' OR VideoName LIKE strftime('%Y%m%d','now','-1 day') || '%P') AND NOT EXISTS (SELECT 1 FROM uploads WHERE VideoName = v.VideoName AND CameraSide = v.CameraSide) ORDER BY VIDEONAME DESC LIMIT 1;")
	video_mode="Parking Mode"
	if [[ -n "${video// /}" ]]; then
		# Parking video found
		true
	else
		# Parking video not found
		echo "$today_datetime-Warning:No video to upload"
		exit
	fi
fi

# Get video file name
video_name=$(echo "$video" | head -c 17)
camera_side=$(echo "$video" | tail -c 2)


# Function
youtube_upload()
{
	youtube_id=$(youtube-upload --privacy "private" --title\="$1" --playlist\="BlavckVue" --description\="$youtube_description, $video_mode" --tags\="$youtube_description, $video_mode" "$1")
	if [[ -n "${youtube_id// /}" ]]; then
		sqlite3 /mnt/PASSPORT/tesla.db -cmd ".timeout 5000" "INSERT INTO uploads (VideoName,CameraSide,YoutubeID) VALUES ('$video_name','$camera_side','$youtube_id');"
		echo "$today_datetime-Success:$video|$youtube_id"
	else
		echo "$today_datetime-Error:$video|$youtube_id|No youtube_id returned"
	fi
}

# Check camera side
if [ $camera_side == "F" ] 
then
	file=$dashcam_storage_front/$video_name\F.mp4
	youtube_upload $file	
elif [ $camera_side == "L" ] 
then
	file=$dashcam_storage_front/$video_name\R.mp4
	youtube_upload $file	
elif [ $camera_side == "B" ] 
then
	file=$dashcam_storage_back/$video_name\F.mp4
	youtube_upload $file	
elif [ $camera_side == "R" ] 
then
	file=$dashcam_storage_back/$video_name\R.mp4
	youtube_upload $file	
else
	echo "$today_datetime-Error:$video|$youtube_id|Wrong CameraSide"
fi