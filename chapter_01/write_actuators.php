#!/usr/bin/php
<?php

define('USE_SYSLOG', 1);
include('../lib/logging.php');
include('../lib/db.php');
include('../lib/misc.php');

define("PHONE_NUM", "+NNNNNNNNNNNN");
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

$gpio_path = "/sys/class/gpio/";
$actuators = array(
	array(
		'name' =>	"LED",
		'file' =>	$gpio_path . "gpio68",
	),

	array(
		'name' =>	"Buzzer",
		'file' =>	$gpio_path . "gpio69",
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

function do_send_sms()
{
	dbg("send SMS...");
	system('gsmsendsms -d /dev/ttyO1 "' . PHONE_NUM . '" "GAS alarm!"');
}

function daemon_body()
{
	global $loop_time;
	global $actuators;

	$sms_delay = db_get_config("sms_delay_s");

	$old_alarm = 0;
	$sms_time = strtotime("1970");

	# The main loop
	dbg("start main loop (loop_time=${loop_time}s)");
	while (sleep($loop_time) == 0) {
		dbg("loop start");

		# Get the "alarm" status and set all alarms properly
		$alarm = db_get_status("alarm");
                foreach ($actuators as $a) {
			$name = $a['name'];
			$file = $a['file'];

			dbg("file=$file alarm=$alarm");
			$ret = gpio_set($file, $alarm);
                       	if (!$ret)
                       		err("unable to write actuator $name");
               	}

		# Send the SMS only during off->on transition
		if ($alarm == "on" && $old_alarm == "off" &&
		    strtotime("-$sms_time seconds") > $sms_delay) {
			do_send_sms();
			$sms_time = strtotime("now");
		}

		$old_alarm = $alarm;

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
