#!/bin/sh

NAME=$(basename $0)

echo "Warning, all data will be dropped!!! [ENTER a wrong root's password to stop]"

# Ok, do the job!
mysql -u root -p <<__EOF__

# Drop all existing data!!!
DROP DATABASE IF EXISTS gas_detector;

# Create new database
CREATE DATABASE gas_detector;

# Grant privileges
GRANT USAGE ON *.* TO user@localhost IDENTIFIED BY 'userpass';
GRANT ALL PRIVILEGES ON gas_detector.* TO user@localhost;
FLUSH PRIVILEGES;

# Select database
USE gas_detector;

#
# Create the system status table
#

CREATE TABLE status (
	n VARCHAR(64) NOT NULL,
	v VARCHAR(64) NOT NULL,
	PRIMARY KEY (n)
) ENGINE=MEMORY;

# Setup default values
INSERT INTO status (n, v) VALUES('alarm', 'off');

#
# Create the system configuration table
#

CREATE TABLE config (
	n VARCHAR(64) NOT NULL,
	v VARCHAR(64) NOT NULL,
	PRIMARY KEY (n)
);

# Setup default values
INSERT INTO config (n, v) VALUES('sms_delay_s', '300');

INSERT INTO config (n, v) VALUES('mq2_gain', '1');
INSERT INTO config (n, v) VALUES('mq4_gain', '1');
INSERT INTO config (n, v) VALUES('mq5_gain', '1');
INSERT INTO config (n, v) VALUES('mq7_gain', '1');
INSERT INTO config (n, v) VALUES('mq2_off', '0');
INSERT INTO config (n, v) VALUES('mq4_off', '0');
INSERT INTO config (n, v) VALUES('mq5_off', '0');
INSERT INTO config (n, v) VALUES('mq7_off', '0');

INSERT INTO config (n, v) VALUES('mq2_th_ppm', '2000');
INSERT INTO config (n, v) VALUES('mq4_th_ppm', '2000');
INSERT INTO config (n, v) VALUES('mq5_th_ppm', '2000');
INSERT INTO config (n, v) VALUES('mq7_th_ppm', '2000');

#
# Create one table per sensor data
#

CREATE TABLE mq2_log (
	t DATETIME NOT NULL,
	v float,
	PRIMARY KEY (t)
);

CREATE TABLE mq4_log (
	t DATETIME NOT NULL,
	v float,
	PRIMARY KEY (t)
);

CREATE TABLE mq5_log (
	t DATETIME NOT NULL,
	v float,
	PRIMARY KEY (t)
);

CREATE TABLE mq7_log (
	t DATETIME NOT NULL,
	v float,
	PRIMARY KEY (t)
);

__EOF__

exit 0
