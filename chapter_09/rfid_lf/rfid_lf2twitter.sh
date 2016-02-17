#!/bin/bash

source ../../lib/logging.sh

NAME=$(basename $0)
logstderr="-s"

t_cmd="t"
t_arg="update"

# The known IDs
declare -gA 'ID2NAME=(
	[111111111111]="user1",
	[222222222222]="user2"
	[6F007F4E1E40]="Rodolfo Giometti"
)'

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
	# Remove the non printable characters
	id=$(echo $id | tr -cd '[:alnum:]')
	info "got tag ID $id"

	# Verify that the tag ID is known and then tweet the event
	name=${ID2NAME[$id]}
	if [ -z "$name" ] ; then
		info "unknow tag ID! Ignored"
	else
		info "Twitting that $name was arrived!"
		$t_cmd $t_arg "$name was arrived!"
	fi
done

exit 0
