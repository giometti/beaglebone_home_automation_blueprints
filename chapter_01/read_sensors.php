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
# Hardware settings
#

$adc_path = "/sys/devices/ocp.3/helper.12/";
$sensors = array(
	array(
		'name' =>	"MQ-2",
		'file' =>	$adc_path . "AIN0",
		'var' =>	"mq2",
		'log' =>	"mq2_log",
	),

	array(
		'name' =>	"MQ-4",
		'file' =>	$adc_path . "AIN2",
		'var' =>	"mq4",
		'log' =>	"mq4_log",
	),

	array(
		'name' =>	"MQ-5",
		'file' =>	$adc_path . "AIN6",
		'var' =>	"mq5",
		'log' =>	"mq5_log",
	),

	array(
		'name' =>	"MQ-7",
		'file' =>	$adc_path . "AIN4",
		'var' =>	"mq7",
		'log' =>	"mq7_log",
	),
);

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
	global $sensors;

	# The main loop
	dbg("start main loop (loop_time=${loop_time}s)");
	while (sleep($loop_time) == 0) {
		dbg("loop start");

		# Read sensors
		foreach ($sensors as $s) {
			$name = $s['name'];
			$file = $s['file'];
			$var = $s['var'];
			$log = $s['log'];

			# Get the converting values
        		$gain = db_get_config($var . "_gain");
        		$off = db_get_config($var . "_off");

       			dbg("gain[$var]=$gain off[$var]=$off");

		        # Read the ADC file
        		$val = file_get_data($file);
        		if ($val === false) {
				err("unable to read sensor $name");
                		continue;
			}

			# Do the translation
			$ppm = $val * $gain + $off;

        		dbg("file=$file val=$val ppm=$ppm");

		        # Store the result into the status table
        		$ret = db_set_status($var, $ppm);
        		if (!$ret) {
                		err("unable to save $name status db_err=%s",
					mysql_error());
                		continue;
        		}

        		# Store the result into the proper log table
        		$ret = db_log_var($log, $ppm);
        		if (!$ret)
                		err("unable to save $name log db_err=%s",
					mysql_error());
		}

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
	#fclose(STDERR);
}

# Get connect to MySQL daemon
db_connect();
db_select("gas_detector");

daemon_body();

exit(0);
