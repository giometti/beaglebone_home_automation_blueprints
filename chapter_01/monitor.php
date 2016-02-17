#!/usr/bin/php
<?php

define('USE_SYSLOG', 1);
include('../lib/logging.php');
include('../lib/db.php');
include('../lib/misc.php');

declare(ticks = 1);

#
# Generic variables
#

$daemonize = true;
$logstderr = false;
$loop_time = 30;

#
# Signals handler
#

function sig_handler($signo)
{
	dbg("signal trapped!");
	die();
}

#
# The daemon body & functions
#

function daemon_body()
{
	global $loop_time;
	global $actuators;

	# The main loop
	dbg("start main loop (loop_time=${loop_time}s)");
	while (sleep($loop_time) == 0) {
		dbg("loop start");

		# Get the gas concentrations and set the "alarm" variable
		$mq2 = db_get_status("mq2");
		$mq2_th_ppm = db_get_config("mq2_th_ppm");
		dbg("mq2/mq2_th_ppm=$mq2/$mq2_th_ppm");
		$mq4 = db_get_status("mq4");
		$mq4_th_ppm = db_get_config("mq4_th_ppm");
		dbg("mq4/mq4_th_ppm=$mq4/$mq4_th_ppm");
		$mq5 = db_get_status("mq5");
		$mq5_th_ppm = db_get_config("mq5_th_ppm");
		dbg("mq5/mq5_th_ppm=$mq5/$mq5_th_ppm");
		$mq7 = db_get_status("mq7");
		$mq7_th_ppm = db_get_config("mq7_th_ppm");
		dbg("mq7/mq7_th_ppm=$mq7/$mq7_th_ppm");

		$alarm = $mq2 >= $mq2_th_ppm ||
			 $mq2 >= $mq2_th_ppm ||
			 $mq2 >= $mq2_th_ppm ||
			 $mq2 >= $mq2_th_ppm ? 1 : 0;
	
			db_set_status("alarm", $alarm); 
		dbg("alarm=$alarm");

		dbg("loop end");
	}
}

#
# Usage
#

function usage()
{
	fprintf(STDERR, "usage: %s [-h] [-d] [-f] [-l] [-T <sec>]\n", NAME);
	fprintf(STDERR, "    -h         - show this message\n");
	fprintf(STDERR, "    -d         - enable debugging messages\n");
	fprintf(STDERR, "    -f         - do not daemonize\n");
	fprintf(STDERR, "    -l         - log on stderr\n");
	fprintf(STDERR, "    -T <sec>   - set the loop time to <sec> seconds\n");

	die();
}

#
# Main
#

# Check the command line
$shortopts  = "hdflT:";
$options = getopt($shortopts);
foreach ($options as $o => $a) {
	switch ($o) {
	case "h":
		usage();

	case "d":
		$debug = true;
		break;

	case "f":
		$daemonize = false;
		break;

	case "l":
		$logstderr = true;
		break;

	case "T":
		$loop_time = $options['T'];
		break;
	}
}

# Open the communication with syslogd
$loglevel = LOG_PID;
if ($logstderr)
	$loglevel |= LOG_PERROR;
openlog(NAME, $loglevel, LOG_USER);

# Install the signals traps
pcntl_signal(SIGTERM, "sig_handler");
pcntl_signal(SIGINT,  "sig_handler");
dbg("signals traps installed");

# Start the daemon
if ($daemonize) {
	dbg("going in background...");
	$pid = pcntl_fork();
	if ($pid < 0) {
		die("unable to daemonize!");
	}
	if ($pid) {
		# The parent can exit...
		exit(0);
	}
	# ... while the children goes on!

	# Set the working directory to /
	chdir("/");

	# Close all of the standard file descriptors as we are running
	# as a daemon
	fclose(STDIN);
	fclose(STDOUT);
	fclose(STDERR);
}

# Get connect to MySQL daemon
db_connect();
db_select("gas_detector");

daemon_body();

exit(0);
