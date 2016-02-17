#!/bin/bash

NAME=$(basename $0)

#
# Usage
#

usage() {
        echo "usage: $NAME <port>" >&2
        exit 1
}

#
# Main
#

# Check the command line
[ $# -lt 1 ] && usage
dev=$1

# Sanity checks
if [ ! -c $dev ] ; then
        echo "$NAME: file $dev is not a char device" >&2
        exit 1
fi

# Setup the serial port at 9600 Baud in raw mode
stty -F $dev 9600 raw

# Read the tags' IDs
cat $dev | while read id ; do
        # Remove the non printable characters and print the data
	echo -n $id | tr '\r' '\n' | tr -cd '[:alnum:]\n'
done

exit 0
