#!/usr/bin/php
<?php

include('../lib/logging.php');
include('../lib/db.php');
include('../lib/misc.php');

define("NAME", basename($argv[0]));
declare(ticks = 1);

#
# Generic variables
#

$daemonize = true;
$logstderr = false;
$loop_time = 15;

$temp_dir = "/sys/bus/w1/devices/28-000004b541e9";
putenv('PATH=' . getenv('PATH') . ':.');

#
# Hardware settings
#

$gpio_path = "/sys/class/gpio/";
$gpios = array(
	"water" =>  $gpio_path . "gpio67",
	"lamp" =>   $gpio_path . "gpio66",
	"cooler" => $gpio_path . "gpio69",
	"pump" =>   $gpio_path . "gpio68",
);

function get_water_level()
{
        global $gpios;

        return gpio_get($gpios["water"]) == 0 ? 1 : 0;
}

function set_lamp($status)
{
	global $gpios;

	gpio_set($gpios["lamp"], $status ? 0 : 1);
}

function set_cooler($status)
{
	global $gpios;

	gpio_set($gpios["cooler"], $status ? 0 : 1);
}

function set_pump($status)
{
	global $gpios;

	gpio_set($gpios["pump"], $status ? 0 : 1);
}

function do_feeder()
{
	system("feeder.sh &");
}

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

	$pump_time = strtotime("now");
	$feeder_time = strtotime("now");

	# The main loop
	dbg("start main loop (loop_time=${loop_time}s)");
	while (sleep($loop_time) == 0) {
		dbg("loop start");

		$alarm_sys = 0;

		#
		# Temperature management
		#

		$ret = temp_get();
		if ($ret === false) {
			err("unable to get temperature!");
			$alarm_sys = 1;
		}
		$temp = $ret;
		dbg("t=$temp");

		# Save status
		db_set_status("water", $temp);

		#
		# Check alarms
		#

		$water_temp_min = db_get_config("water_temp_min_alarm");
		$water_temp_max = db_get_config("water_temp_max_alarm");
		$val = ($temp < $water_temp_min ||
			$temp > $water_temp_max) ? 1 : 0;
		db_set_status("alarm_temp", $val);

       		# Store the result into the proper log table
       		db_log_var("temp_log", $temp);

		$water_level = get_water_level();
		db_set_status("alarm_level", $water_level);

		#
		# Lamp management
		#

		# The lamp is directly managed by the force_lamp switch

		$lamp = db_get_status("force_lamp");

		# Set the new status
		set_lamp($lamp);
		db_set_status("lamp", $lamp);
		dbg("lamp %sactivated", $lamp ? "" : "de");

		#
		# Cooler management
		#

		# The cooler must be enabled if temp > water_temp_max in order
		# to try to reduce the temperature of the water...
		$water_temp_max = db_get_config("water_temp_max");
		$cooler = $temp > $water_temp_max ? 1 : 0;

		# We must force on?
		$force_cooler = db_get_status("force_cooler");
		$cooler = $force_cooler ? 1 : $cooler;

		# Set the new status
		set_cooler($cooler);
		db_set_status("cooler", $cooler);
		dbg("cooler %sactivated", $cooler ? "" : "de");

		#
		# Pump management
		#

		# The pump must be on for pump_t_on delay time and off for
		# pump_t_off delay time (if not forced of course...)
		$force_pump = db_get_status("force_pump");
		$pump = db_get_status("pump");
               	$pump_interval = $pump ? db_get_config("pump_t_on") :
					 db_get_config("pump_t_off");
		if ($force_pump ||
		    strtotime("-$pump_time seconds") > $pump_interval) {
			$pump_time = strtotime("now");

			$pump = $force_pump ? 1 : !$pump;
		}

		# Set the new status
		set_pump($pump);
		db_set_status("pump", $pump);
		dbg("pump %sactivated", $pump ? "" : "de");

		#
		# Feeder management
		#

		$force_feeder = db_get_status("force_feeder");
		$feeder_interval = db_get_config("feeder_interval");
		if ($force_feeder ||
		    (strtotime("-$feeder_time seconds") > $feeder_interval)) {
                        $feeder_time = strtotime("now");

			do_feeder();
			db_set_status("force_feeder", 0);
			dbg("feeder activated");
		}

		# In the end we can safely store the generic alarm status
		db_set_status("alarm_sys", $alarm_sys);
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
db_select("aquarium_mon");

daemon_body();

exit(0);
