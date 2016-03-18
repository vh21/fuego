#!/bin/bash
#
# maintain_config_link.sh
#
# maintain_config_link.sh expects /var/lib/jenkins/config.xml to be a symlink
# to /userdata/conf/config.xml.  It uses inotifywait to monitor
# /var/lib/jenkins for any change in the link status, and if the link
# disappears it restores the symlink
#
# this needs inotifywait, from the inotify-tools package
#
# this is needed because Jenkins removes the symlink when it edits
# the config.xml file, but we want this file to appear in /userdata
# where it can be accessed (and edited) in the host filesystem

#set -x

dest_dir=/var/lib/jenkins
source=/userdata/conf/config.xml
dest=/var/lib/jenkins/config.xml

function fixlink()
{
	# check for <dest> still being a symlink
	if [ ! -L "$dest" ]; then
		echo $dest is NOT a symlink - fixing it now.
		mv -f $dest $source ;
		ln -s $source $dest ;
	else
		echo $dest is a symlink - everything is OK.
	fi
}

fixlink
while true
do
	inotifywait -e move $dest_dir && fixlink 
done
