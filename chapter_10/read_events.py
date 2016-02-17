#!/usr/bin/env python

from __future__ import print_function
import os
import sys
import logging
import getopt
import string
from evdev import InputDevice, categorize, ecodes
from select import select

logging.basicConfig(level = logging.INFO)

NAME = os.path.basename(sys.argv[0])
GPIO = [-1, -1, 69, 44, 45, -1, -1, -1, -1, -1, -1, 68]

#
# Local functions
#

def gpio_get(gpio):
	fd = open("/sys/class/gpio/gpio" + str(gpio) + "/value", "r")
	val = fd.read()
	fd.close()
	return int(val)

def gpio_set(gpio, val):
	fd = open("/sys/class/gpio/gpio" + str(gpio) + "/value", "w")
	v = fd.write(str(val))
	fd.close()

def usage():
        print("usage: ", NAME, " [-h] <inputdev>", file=sys.stderr)
        sys.exit(2);

#
# Main
#

try:
        opts, args = getopt.getopt(sys.argv[1:], "h",
                        ["help"])
except getopt.GetoptError, err:
        # Print help information and exit:
        print(str(err), file=sys.stderr)
        usage()

for o, a in opts:
        if o in ("-h", "--help"):
                usage()
        else:
                assert False, "unhandled option"

# Check command line
if len(args) < 1:
        usage()

# Try to open the input device
try:
        dev = InputDevice(args[0])
except:
        print("invalid input device", args[0], file=sys.stderr)
        sys.exit(1);

logging.info(dev)
logging.info("hit CTRL+C to stop")

# Start the main loop
for event in dev.read_loop():
	if event.type == ecodes.EV_KEY and event.value == 1:
		# Get the key code and convert it to the corresponding GPIO
		code = event.code
		if code < 0 or code > len(GPIO):
			gpio = -1
		else:
			gpio = GPIO[code]
		logging.info("got code %d -> GPIO%d" % (code, gpio))

		if gpio > 0:
			# Get current GPIO status and invert it
			status = gpio_get(gpio)
			status = 1 - status
			gpio_set(gpio, status)
			logging.info("turning GPIO%d %d -> %d" %
				(gpio, 1 - status, status))
		else:
			logging.info("invalid button")
