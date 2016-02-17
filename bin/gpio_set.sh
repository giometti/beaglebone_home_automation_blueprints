#!/bin/bash

NAME=$(basename $0)
declare -a valid_gpios=(60 66 67 69 68 45 44 23 26 47 46 27 65 39)

usage() {
	echo "usage: $NAME <num> <dir> [<0|1>]" >&2
	exit 1
}

[ $# -lt 2 ] && usage
num=$1
dir=$2
val=$3

# Sanity checks
if ! [[ ${valid_gpios[*]} =~ $(echo "\<$num\>") ]] ; then
	echo -n "$NAME: GPIO #$num not allowed, " >&2
	echo    "must be in [${valid_gpios[*]}]" >&2
	exit 1
fi

if [ "$dir" != "in" -a "$dir" != "out" ] ; then
	echo "$NAME: invalid direction" >&2
	exit 1
fi

# Export the GPIO and set it as output
echo $num > /sys/class/gpio/export
echo $dir > /sys/class/gpio/gpio$num/direction || exit 1
if [ "$dir" = "out" -a -n "$val" ] ; then
	echo $val > /sys/class/gpio/gpio$num/value || exit 1
fi

exit 0
