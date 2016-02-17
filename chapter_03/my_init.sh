#!/bin/sh

NAME=$(basename $0)

echo "Warning, all data will be dropped!!! [ENTER a wrong root's password to stop]"

# Ok, do the job!
mysql -u root -p <<__EOF__

# Drop all existing data!!!
DROP DATABASE IF EXISTS aquarium_mon;

# Create new database
CREATE DATABASE aquarium_mon;

# Grant privileges
GRANT USAGE ON *.* TO user@localhost IDENTIFIED BY 'userpass';
GRANT ALL PRIVILEGES ON aquarium_mon.* TO user@localhost;
FLUSH PRIVILEGES;

# Select database
USE aquarium_mon;

#
# Create the system status table
#

CREATE TABLE status (
	n VARCHAR(64) NOT NULL,
	v VARCHAR(64) NOT NULL,
	PRIMARY KEY (n)
) ENGINE=MEMORY;

# Setup default values
INSERT INTO status (n, v) VALUES('alarm_sys', '0');
INSERT INTO status (n, v) VALUES('alarm_level', '0');
INSERT INTO status (n, v) VALUES('alarm_temp', '0');
INSERT INTO status (n, v) VALUES('water', '21');
INSERT INTO status (n, v) VALUES('cooler', '0');
INSERT INTO status (n, v) VALUES('pump', '0');
INSERT INTO status (n, v) VALUES('lamp', '0');
INSERT INTO status (n, v) VALUES('force_cooler', '0');
INSERT INTO status (n, v) VALUES('force_pump', '0');
INSERT INTO status (n, v) VALUES('force_lamp', '0');
INSERT INTO status (n, v) VALUES('force_feeder', '0');

#
# Create the system configuration table
#

CREATE TABLE config (
	n VARCHAR(64) NOT NULL,
	v VARCHAR(64) NOT NULL,
	PRIMARY KEY (n)
);

# Setup default values
INSERT INTO config (n, v) VALUES('pump_t_on', '20');
INSERT INTO config (n, v) VALUES('pump_t_off', '60');
INSERT INTO config (n, v) VALUES('feeder_interval', '60');
INSERT INTO config (n, v) VALUES('water_temp_max', '27');
INSERT INTO config (n, v) VALUES('water_temp_min_alarm', '18');
INSERT INTO config (n, v) VALUES('water_temp_max_alarm', '29');

#
# Create one table per sensor data
#

CREATE TABLE temp_log (
	t DATETIME NOT NULL,
	v FLOAT,
	PRIMARY KEY (t)
);

__EOF__

exit 0
