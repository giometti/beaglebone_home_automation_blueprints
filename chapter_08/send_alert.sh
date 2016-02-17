#!/bin/bash

NAME=$(basename $0)

# Settings
LOCK_FILE="/tmp/send_alert.lock"

ALERT_TO="name@mydomain.com"
ALERT_FROM="BBB Guardian <myaccount@gmail.com>"
ALERT_SUBJ="Alert from BBB Guardian"
ALERT_MESG='
Intrusion detetcted at %time.\n
\n
Your BBB Guardian
'
ALERT_LIST="/tmp/send_alert.list"
ALERT_LIMIT=5

#
# Local functions
#

function log ( ) {
	echo "[$cam] $1"
}

function send_alert {
	# Build the attachments list
	[ ! -e $ALERT_LIST ] && return
	for f in $(head -n $ALERT_LIMIT $ALERT_LIST) ; do
		list="-a $f $list"
	done

	# Send the letter
	echo -e ${ALERT_MESG/\%time/$time} | \
		mail -s "$ALERT_SUBJ" -r "$ALERT_FROM" $list "$ALERT_TO"
}

usage() {
        echo "usage [to add image]: $NAME <timestamp> <cam #> <filepath>" >&2
        echo "usage [to send alert]: $NAME <timestamp> <cam #>" >&2
        exit 1
}


#
# Main
#

# Check command line
[ $# -lt 2 ] && usage

( # Wait for lock on LOCK_FILE (fd 99) for 10 seconds
flock -w 10 -x 99 || exit 1

if [ $# -eq 3 ] ; then
	# Must add the picture to the list
	time=$1
	cam=$2
	path=$3

	log "got new picture $path at $time"
	echo "$path" >> $ALERT_LIST
elif [ $# -eq 2 ] ; then
	# Send the mail alert
	time=$1
	cam=$2

	log "sending alert at $time"
	send_alert
	rm $ALERT_LIST
else
	cam="?"
	log "invalid command!"
fi

# Release the lock
) 99>$LOCK_FILE

exit 0
