#!/bin/bash

HOST=192.168.0.10:9091

KEEP_FOREVER_IDS="2" # seperate ID list by space

# use transmission-remote to get torrent list from transmission-remote list
# use sed to delete first / last line of output, and remove leading spaces
# use cut to get first field from each line
TORRENTLIST=`transmission-remote $HOST --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited -d ' ' --fields=1`
# for each torrent in the list
for TORRENTID in $TORRENTLIST
do
  TORRENTID=`echo $TORRENTID | sed 's:*::'`
  # removes asterisk * from torrent ID# which had error associated with it
  echo "* * * * * Operations on torrent ID $TORRENTID starting. * * * * *"
  # check if torrent download is completed
  DL_COMPLETED=`transmission-remote $HOST -t $TORRENTID -i | grep "Percent Done: 100%"`
  # check torrent’s current state is "Stopped", "Finished", or "Idle"
  STATE_STOPPED=`transmission-remote $HOST -t $TORRENTID -i | grep "State: Stopped\|Finished\|Idle"`
  # if the torrent is "Stopped", "Finished", or "Idle" after downloading 100%…
  if [ "$DL_COMPLETED" != "" ] && [ "$STATE_STOPPED" != "" ]; then
    # remove the torrent from Transmission
    echo "Torrent $TORRENTID is completed."
    if [[ " $KEEP_FOREVER_IDS " =~ .*\ $TORRENTID\ .* ]]; then
	echo "Torrent $TORRENTID is to be saved forever. Ignoring."
    else
	echo "Removing torrent from list."
	transmission-remote $HOST -t $TORRENTID -rad
    fi
  else
    echo "Torrent $TORRENTID is not completed. Ignoring."
  fi
  echo "* * * * * Operations on torrent ID $TORRENTID completed. * * * * *"
done

# get ids
# transmission-remote 192.168.0.10:9091 --list | sed -e '1d;$d;s/^ *//' | cut --only-delimited -d ' ' --fields=1

# check id #2
# transmission-remote 192.168.0.10:9091 -t 2 -i
