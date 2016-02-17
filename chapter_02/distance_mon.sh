#!/bin/bash

NAME=$(basename $0)
ADC_DEV="/sys/devices/ocp.3/helper.12/AIN0"
TTY_DEV="/dev/ttyUSB0"

#
# Logging functions
#

function dbg () {
	[ $debug ] && echo "$NAME: $1"
}

function info () {
	echo "$NAME: $1"
}

function err () {
	echo "$NAME: $1" >&2
}

#
# Sensor reading functions
#

function read_adc () {
	n=$(cat $ADC_DEV)

	d=$(bc -l <<< "$k * 3.3 * $n/4095 / 0.00161")
	printf "%.0f\n" $d
}

function read_tty () {
	while read d < $TTY_DEV ; do
		[[ "$d" =~ R[0-9]{2,3} ]] && break
	done

	# Drop the "R" character
	d=${d#R}

	# Drop the leading "0"
	echo ${d#0}
}

#
# LEDs management
#

function leds_man () {
	d=$1

	# Calculate the blinking frequency with the following
	# fixed values:
	#    f=1Hz  if d=100cm
	#    f=25Hz if d=25cm
	f=$((25 - 21 * ( d - 25 ) / 75))
	[ $f -gt 25 ] && f=25
	[ $f -lt 1 ] && f=1

	if [ "$d" -gt 500 ] ; then
		./led_set.sh white     0
		./led_set.sh yellow    0 
		./led_set.sh red_far   0
		./led_set.sh red_mid   0
		./led_set.sh red_near  0

		return
	fi

	if [ "$d" -le 500 -a "$d" -gt 200 ] ; then
		./led_set.sh white    -1
		./led_set.sh yellow    0
		./led_set.sh red_far   0
		./led_set.sh red_mid   0
		./led_set.sh red_near  0

		return
	fi

	if [ "$d" -le 200 -a "$d" -gt 100 ] ; then
		./led_set.sh white    -1
		./led_set.sh yellow   -1
		./led_set.sh red_far   0
		./led_set.sh red_mid   0
		./led_set.sh red_near  0

		return
	fi

	if [ "$d" -le 100 -a "$d" -gt 50 ] ; then
		./led_set.sh white    -1
		./led_set.sh yellow   -1
		./led_set.sh red_far  $f
		./led_set.sh red_mid   0
		./led_set.sh red_near  0

		return
	fi

	if [ "$d" -le 50 -a "$d" -gt 20 ] ; then
		./led_set.sh white    -1
		./led_set.sh yellow   -1
		./led_set.sh red_far  -1
		./led_set.sh red_mid  $f
		./led_set.sh red_near  0

		return
	fi

	# if -le 20
	./led_set.sh white    -1
	./led_set.sh yellow   -1
	./led_set.sh red_far  -1
	./led_set.sh red_mid  -1
	./led_set.sh red_near -1
}

#
# Usage
#

usage() {
        echo "usage: $NAME [-h] [-k <val>] adc|serial" >&2
        exit 1
}

#
# Main
#

k=1

# Check the command line
TEMP=$(getopt -o hdk: -n $NAME -- "$@")
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

        -k)
                k="$2"
                shift 2
                ;;
        --)
                shift
                break
                ;;

        *)
                echo "$NAME: internal error!" >&2
                exit 1
                ;;
        esac
done

[ $# -lt 1 ] && usage
setup=$1

# Sanity checks
case $setup in
adc)
	# Use the ADC to get the distance
	d_fun=read_adc
	;;

serial)
	# Use the serial port to get the distance
	d_fun=read_tty
	;;

*)
	# Invalid selection
	echo "$NAME: invalid setup value! Must be adc|serial" >&2
	exit 1
	;;
esac
dbg "d_fun=$d_fun k=$k"

# Ok, do the job
while sleep .1 ; do
	# Read the current distance from the sensor
	d=$($d_fun)
	dbg "d=$d"

	# Manage the LEDs
	leds_man $d
done

exit 0
