#!/bin/bash

NAME=$(basename $0)

AIN_PATH="/sys/devices/ocp.3/helper.12"

#
# Signals handler
#

function sig_handler () {
        do_exit=true
}

#
# Usage
#

usage() {
        echo "usage: $NAME <table>" >&2
        exit 1
}

#
# Main
#

# Check the command line
[ $# -lt 1 ] && usage
dev=$1

# Sanity checks
if [ ! -e $AIN_PATH/$dev ] ; then
	echo "$NAME: ADC device $AIN_PATH/$dev not ready" >&2
        exit 1
fi

# Install the signals traps
trap sig_handler SIGTERM SIGINT

# Start sampling the data till a signal occours
echo "$NAME: collecting data into file sample.log (press CTRL+C to stop)..."

do_exit=false
t0=$(date '+%s.%N')
( while ! $do_exit ; do
	t=$(date '+%s.%N')
	v=$(cat $AIN_PATH/$dev)

	echo "$(bc -l <<< "$t - $t0") $v"

	# Sleep till the next period
	sleep $(bc -l <<< ".5 - $(date '+%s.%N') + $t")
done ) | tee sample.log

# Plot the data
echo "$NAME: done. Now generate the plot..."

gnuplot <<EOF
set terminal png size 800,600 enhanced font "Helvetica,20"
set output 'sample.png'
set autoscale
set nokey
set grid lw 1
show grid
set xlabel "\nTime"
set ylabel 'sample'
set xtics rotate
plot "sample.log" using 1:2 with lines
EOF

echo "$NAME: done. Data plotted into file sample.png"

exit 0
