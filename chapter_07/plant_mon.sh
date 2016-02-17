#!/bin/bash

NAME=$(basename $0)

STATUS_FILE="/var/www/plant.status"
LOCK_FILE="/var/www/plant.lock"
IMG_FILE="/var/www/webcam-shot.jpg"

LIGHT_DEV="/sys/devices/ocp.3/helper.12/AIN1"
INT_TEMP_DEV="/sys/bus/w1/devices/28-000004b541e9/w1_slave"
EXT_TEMP_DEV="2 0x5a 0x07"
MOISTURE_DEV="/sys/devices/ocp.3/helper.12/AIN0"

LIGHT_LOW=100
LIGHT_HIGH=850

source ../lib/logging.sh

# Take a new picture every 10 minutes by default
min=10

#
# Sensor reading functions
#

function adc_read () {
        ret=0

        while [ -z "$v" ] ; do
                v=$(cat $1)
        done

        echo -n $v
}

function w1_read () {
        ret=0

        while [ -z "$v" ] ; do
                v=$(cat $1 | grep 't=' | cut -d '=' -f 2)
        done

        echo "scale=2; $v / 1000." | bc
}

function i2c_read () {
        ret=0

        while [ -z "$v" ] ; do
                v=$(i2cget -y $EXT_TEMP_DEV wp)
        done

        echo "$(printf "ibase=16; %X\n" $v | bc) * 0.02 - 273.15" | bc
}

#
# Misc functions
#

function json_decode ( ) {
	tr ',{}' '\n' | grep "$1" | cut -d ':' -f 2
}

function json_encode () {
	echo -n "{"
	while true ; do
		echo -n "\"$1\":$2"
		shift 2
		[ -z "$1" -o -z "$2" ] && break
		echo -en ","
	done
	echo -en "}"
}

function read_sensors ( ) {
	lig_levl=$(adc_read $LIGHT_DEV)
	int_temp=$(w1_read $INT_TEMP_DEV)
	ext_temp=$(i2c_read $EXT_TEMP_DEV)
	msr_mois=$(adc_read $MOISTURE_DEV)
	dbg "lig_levl=$lig_levl int_temp=$int_temp ext_temp=$ext_temp msr_mois=$msr_mois"
	dbg "curr_date=$(date "+%H%M") next_date=$next_date"
}
		
function do_picture ( ) {
	# Compute the light level
	ll="mid"
	[ $lig_levl -le $LIGHT_LOW ] && ll="low"
	[ $lig_levl -ge $LIGHT_HIGH ] && ll="high"

	# Take the picture
	fswebcam -q --title "My lovely plant" \
		    --info "Temp: $ext_temp/$int_temp°C - Light: $ll" \
		    --jpeg 85 $IMG_FILE

	# Compute the next picture time
	date -d "now +$1 minutes" "+%H%M"
}

#
# Signals handler
#

function sig_handler () {
        dbg "signal trapped!"
        exit 0
}

#
# The daemon body
#

function daemon_body () {
	# Read plant data and take the first picture
	read_sensors
	next_date=$(do_picture)

        # The main loop
        dbg "start main loop"
        while sleep 1 ; do
		# Read plant data from all sensors
		read_sensors
		
		( # Wait for lock on LOCK_FILE (fd 99) for 10 seconds
		flock -w 10 -x 99 || exit 1

		# Read the user parameters
		cff_mois=$(cat $STATUS_FILE | json_decode cff_mois)
		[ -z "$cff_mois" ] && cff_mois=1
		dbg "cff_mois=$cff_mois"

		# Compute the moisture level
		est_mois=$msr_mois
		if (( $(bc <<< "$int_temp < $ext_temp") == 1 )) ; then
			est_mois=$(bc -l <<< "$msr_mois + $cff_mois * ( $ext_temp - $int_temp )")
		fi
		dbg "est_mois=$est_mois"
	
		# Write back the plant parameters
		json_encode lig_levl $lig_levl \
				int_temp $int_temp \
				ext_temp $ext_temp \
				msr_mois $msr_mois \
				cff_mois $cff_mois \
				est_mois $est_mois > $STATUS_FILE
		
		# Release the lock
		) 99>$LOCK_FILE

		# Have to take a new picture?
		[ $(date "+%H%M") == "$next_date" ] && next_date=$(do_picture)
        done
}

# Usage
#

function usage () {
        echo "usage: $NAME [-h] [-d] [-f] [-k <val>] [-l]" >&2
        echo "    -h        - show this message" >&2
        echo "    -d        - enable debugging messages" >&2
        echo "    -f        - do not daemonize" >&2
        echo "    -k <val>  - take a picture every <val> minutes (default $min)" >&2
        echo "    -l        - log on stderr" >&2

        exit 1
}

#
# Main
#

# Check the command line
TEMP=$(getopt -o hdfk:l -n $NAME -- "$@")
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

        -f)
                daemonize=""
                shift
                ;;

        -k)
                min="$2"
                shift 2
                ;;

        -l)
                logstderr="--stderr"
                shift
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

dbg "min=$min"

# Create the status & lock files
touch $STATUS_FILE && chmod a+rw $STATUS_FILE
touch $LOCK_FILE && chmod a+rw $LOCK_FILE

# Install the signals traps
trap sig_handler SIGTERM SIGINT
dbg "signals traps installed"

# Start the daemon
if [ -n "$daemonize" ] ; then
        dbg "going in background..."

        # Set the working directory to /
        cd /
fi
[ -z "$logstderr" ] && tmp="2>&1"
eval daemon_body </dev/null >/dev/null $tmp $daemonize

exit 0
