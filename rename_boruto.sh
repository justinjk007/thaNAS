#!/bin/bash

# Boruto - Naruto Next Generations - 177 (1080p).mkv ==>  Boruto - Naruto Next Generations - S01E177.mkv

cd "$HOME/media/anime/Boruto - Naruto Next Generations/Season 1"

for entry in *
do
    episode=`echo $entry | sed -r 's/.*Boruto\ -\ Naruto\ Next\ Generations\ - ([0-9]*).*/\1/'`
    if [ -n "$episode" ]; then
	echo "BAD ENTRY: $entry"
	mv "${entry}" "Boruto - Naruto Next Generations - S01E${episode}.mkv"
	# After renaming entry, move it out of this folder and then bring it back so plex can re-check episode
	mv "Boruto - Naruto Next Generations - S01E${episode}.mkv" "../../"
	sleep 3s
	mv "../../Boruto - Naruto Next Generations - S01E${episode}.mkv" "."
	episode=""
    else
	echo "GOOD ENTRY: $entry"
    fi
done
