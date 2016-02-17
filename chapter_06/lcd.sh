#!/bin/bash

NAME=$(basename $0)

PRS_AVG=500
PRS_AMP=200
SND_AVG=200

source ../lib/logging.sh

#
# Common functions
#

function hex2dec ( ) {
	v=$(printf "%X" $1)
	echo "ibase=16; $v" | bc
}

#
# GUI functions & defines
#

ES_CLEAR_LN="\033[2K\r"

FC_DEFAULT="\e[39m"
FC_RED="\e[31m"
FC_GREEN="\e[32m"
FC_BLUE="\e[34m"
FC_LIGHT_YELLOW="\e[93m"
FC_LIGHT_BLUE="\e[94m"
FC_LIGHT_MAGENTA="\\e[95m"

BC_DEFAULT="\e[49m"
BC_RED="\e[41m"

CH_PULSE=" .oOo."

function clear_scr ( ) {
	echo -en "\033[2J"
}

function goto_xy ( ) {
	echo -en "\033[$1;$2H"
}

#
# Usage
#

usage() {
	echo "usage: $NAME [-h] [-d] [-l] [-m <level>] [-p <level>] [-s level]" >&2
	echo "       -m <level> min averange pressure level (default $PRS_AVG)" >&2
	echo "       -p <level> min amplitude pressure level (default $PRS_AMP)" >&2
	echo "       -s <level> min averange sound level (default $SND_AVG)" >&2
	exit 1
}

#
# Main
#

# Check the command line
TEMP=$(getopt -o hdlm:p:s: -n $NAME -- "$@")
[ $? != 0 ] && exit 1
eval set -- "$TEMP"
while true ; do
        case "$1" in
        -h)
                usage
                ;;

        -d)
                debug="true"
                shift
                ;;

        -l)
                logstderr="-s"
                shift
                ;;

	-m)
		PRS_AVG=$2
		shift 2
		;;

	-p)
		PRS_AMP=$2
		shift 2
		;;

	-s)
		SND_AVG=$2
		shift 2
		;;

        --)
                shift
                break
                ;;

        *)
                err "internal error!"
                exit 1
                ;;
        esac
done

# Ok, do the job
clear_scr

tick=1
while true ; do
	# Read the temperature from the sensor and convert it in C
	t=$(i2cget -y 2 0x5a 0x07 wp)
	t=$(hex2dec $t)
	t=$(echo "$t * 0.02 - 273.15" | bc)

	# Read the pressure and sound data from the "adc" tool
	read -u 0 v b s

	# Draw the GUI

	# Check for a minimum pressure, otherwise drop to 0 sound and
	# pressure data in order to not enable any alarm
	if [ $v -lt $PRS_AVG ] ; then
		s=0
		b=0
		enabled="false"
	else
		enabled="true"
	fi

	# Rewrite the screen
	goto_xy 0 0

	echo -en "[${CH_PULSE:$tick:1}] "
	echo -e "${FC_LIGHT_MAGENTA}BBB - BABY SENTINEL${FC_DEFAULT}\n"

	echo -en "TEMPERATURE (C):"
	if (( $(bc <<< "$t > 37.00") == 1 )) ; then
		echo -e "$FC_RED"
		t_alrm="true"
	else
		echo -e "$FC_GREEN"
		t_alrm="false"
	fi
	figlet -f small -W -r -w 32 "$t"
	echo -e "$FC_DEFAULT"

	echo -en "SOUND LEVEL:"
	if $enabled && [ $s -gt $SND_AVG ] ; then
		echo -e "$FC_RED"
		s_alrm="true"
	else
		echo -e "$FC_DEFAULT"
		s_alrm="false"
	fi
	figlet -f small -W -r -w 32 "$s"

	echo -en "BREATH LEVEL:"
	if $enabled && [ $b -lt $PRS_AMP ] ; then
		echo -e "$FC_RED"
		b_alrm="true"
	else
		echo -e "$FC_DEFAULT"
		b_alrm="false"
	fi
	figlet -f small -W -r -w 32 "$b"
	echo -en "${ES_CLEAR_LN}${FC_LIGHT_RED}ALARMS: ${FC_DEFAULT}"
	$t_alrm && echo -en "${BC_RED}TEMP. "
	$s_alrm && echo -en "${BC_RED}SOUND "
	$b_alrm && echo -en "${BC_RED}BREATH "
	echo -e "${BC_DEFAULT}"

	# Print some debugging messages if requested
	dbg "$(printf "t=%0.2f v=% 4d b=% 4d s=% 4d" $t $v $b $s)"
	dbg "PRS_AVG=$PRS_AVG PRS_AMP=$PRS_AMP SND_AVG=$SND_AVG"

	tick=$(( ($tick + 1) % ${#CH_PULSE} ))
done

exit 0
