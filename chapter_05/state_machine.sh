#!/bin/bash

NAME=$(basename $0)

SOUND_DEV="/sys/devices/ocp.3/helper.12/AIN0"
LIGHT_DEV="/sys/devices/ocp.3/helper.12/AIN1"

source ../lib/logging.sh
source ./config.sh

# Check the configuration settings. If not specified use default values
[ -z "$TIMEOUT" ] && TIMEOUT=60
[ -z "$SOUND_TH" ] && SOUND_TH=500
[ -z "$LIGHT_TH" ] && LIGHT_TH=500
if [ -z "$WHATSAPP_USER" ] ; then
	err "you must define WHATSAPP_USER!"
	exit 1
fi

#
# Sensor reading functions
#

function read_sound () {
	ret=0

	while [ -z "$v" ] ; do
      		v=$(cat $SOUND_DEV)
	done
      	[ "$v" -gt $SOUND_TH ] && ret=1
      
      	echo -n $ret 
}

function read_light () {
	ret=0

	while [ -z "$v" ] ; do
      		v=$(cat $LIGHT_DEV)
	done
      	[ "$v" -gt $LIGHT_TH ] && ret=1
      
      	echo -n $ret 
}

#
# LEDs management
#

function set_led () {
	name=$1
	val=$2

	case $val in
	on)
		echo none > /sys/class/leds/c5\:$name/trigger
        	echo 255 > /sys/class/leds/c5\:$name/brightness
        	;;

	off)
		echo none > /sys/class/leds/c5\:$name/trigger
        	echo 0 > /sys/class/leds/c5\:$name/brightness
        	;;

	blink)
        	t=$((1000 / 2))

        	echo timer > /sys/class/leds/c5\:$name/trigger
        	echo $t > /sys/class/leds/c5\:$name/delay_on
        	echo $t > /sys/class/leds/c5\:$name/delay_off
        	;;

	*)
		err "invalid LED status! Abort"
		exit 1
		;;
	esac
}

function signal_status () {
	s=$1

	case $s in
	IDLE)
		set_led yellow off
		set_led red off
		;;

	SOUND)
		set_led yellow blink
		set_led red off
		;;

	RUNNING)
		set_led yellow on
		set_led red off
		;;

	NO_SOUND)
		set_led yellow on
		set_led red blink
		;;

	DONE)
		set_led yellow on
		set_led red on
		;;

	LIGHT)
		set_led yellow blink
		set_led red on
		;;

	ROOM)
		set_led yellow off
		set_led red on
		;;

	NO_LIGHT)
		set_led yellow off
		set_led red blink
		;;
	esac

	return
}

#
# Alert management
#

function send_alert () {
	msg=$1

	dbg "user=$WHATSAPP_USER msg=\"$1\""
	yowsup-cli demos -c yowsup-cli.config -s $WHATSAPP_USER "$msg" 

	return
}

#
# Statuses transactions
#

function change_status () {
	status=$1
	sound=$2
	light=$3
	t0=$4

	t=$(date "+%s")

        dbg "status=$status sound=$sound light=$light t-t0=$(($t - $t0))"

	case $status in
	IDLE)
		if [ $sound -eq 1 ] ; then
			echo SOUND
			return
		fi
		;;

	SOUND)
		if [ $sound -eq 1 -a $(($t - $t0)) -gt $TIMEOUT ] ; then
			echo RUNNING
			return
		fi
		if [ $sound -eq 0 ] ; then
			echo IDLE
			return
		fi
		;;

	RUNNING)
		if [ $sound -eq 0 ] ; then
			echo NO_SOUND
			return
		fi
		;;

	NO_SOUND)
		if [ $sound -eq 0 -a $(($t - $t0)) -gt $TIMEOUT ] ; then
			echo DONE
			return
		fi
		if [ $sound -eq 1 ] ; then
			echo RUNNING
			return
		fi
		;;

	DONE)
		if [ $light -eq 1 ] ; then
			echo LIGHT
			return
		fi
		;;

	LIGHT)
		if [ $light -eq 1 -a $(($t - $t0)) -gt $TIMEOUT ] ; then
			echo ROOM
			return
		fi
		if [ $light -eq 0 ] ; then
			echo DONE
			return
		fi
		;;

	ROOM)
		if [ $light -eq 0 ] ; then
			echo NO_LIGHT
			return
		fi
		;;

	NO_LIGHT)
		if [ $light -eq 0 -a $(($t - $t0)) -gt $TIMEOUT ] ; then
			echo IDLE
			return
		fi
		if [ $light -eq 1 ] ; then
			echo NO_LIGHT
			return
		fi
		;;

	*)
		err "invalid status! Abort"
		exit 1
		;;
	esac

	# No status change!
	echo $status
}

#
# Usage
#

usage() {
        echo "usage: $NAME [-h] [-d] [-l]" >&2
        exit 1
}

#
# Main
#

# Check the command line
TEMP=$(getopt -o hdl -n $NAME -- "$@")
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
dbg "using TIMEOUT=$TIMEOUT SOUND_TH=$SOUND_TH LIGHT_TH=$LIGHT_TH"

status="IDLE"
t0=0

signal_status $status
while sleep 1 ; do
	dbg "old-status=$status"

        # Read the sensors
        sound=$(read_sound)
        light=$(read_light)

	# Change status?
	new_status=$(change_status $status $sound $light $t0)
	if [ "$new_status" != "$status" ] ; then
		t0=$(date "+%s")

        	# Set the leds status
		signal_status $new_status

		# We have to send any alert?
		case $new_status in
		RUNNING)
			# Send the message during SOUND->RUNNING transaction
			# only
			[ "$status" == SOUND ] && send_alert "washing machine is started!"
			;;

		DONE)
			# Send the message during NO_SOUND->DONE transaction
			# only
			[ "$status" == NO_SOUND ] && send_alert "washing machine has finished!"
			;;

		*)
			# Nop
			;;
		esac
	fi
	dbg "new-status=$new_status"

	status=$new_status
done

exit 0
