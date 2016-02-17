#!/usr/bin/env python

from __future__ import print_function
import os
import sys
import getopt
import string
import syslog
import resource
import time

from openzwave.node import ZWaveNode
from openzwave.value import ZWaveValue
from openzwave.scene import ZWaveScene
from openzwave.controller import ZWaveController
from openzwave.network import ZWaveNetwork
from openzwave.option import ZWaveOption
from louie import dispatcher, All

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
import json
import cgi

#
# Default settings
#

NAME = os.path.basename(sys.argv[0])
debug = False
logstderr = False
log = "Info"
timeout_s = 20
port = 8080

# Default system status
values = {
	"switch" :  "off",
	"power"  :    0.0,
	"temp"   :      0,
	"hum"    :      0,
	"lum"    :      0,
	"bat_lvl":      0,
	"sensor" :   "no",
}

#
# Logging functions
#

def dbg(x):
        if not debug:
                return

        syslog.syslog(syslog.LOG_DEBUG, str(x))

def info(x):
        syslog.syslog(syslog.LOG_INFO, str(x))

#
# Z-Wave related functions
#

def louie_value(network, node, value):
	# Record all new status changing
	if (value.label == "Switch"):
		values["switch"] = "on" if value.data else "off"
	elif (value.label == "Power"):
		values["power"] = value.data
	elif (value.label == "Temperature"):
		values["temp"] = value.data
	elif (value.label == "Relative Humidity"):
		values["hum"] = value.data
	elif (value.label == "Luminance"):
		values["lum"] = value.data
	elif (value.label == "Battery Level"):
		values["bat_lvl"] = value.data
	elif (value.label == "Sensor"):
		values["sensor"] = "yes" if value.data else "no"
	dbg("dev=%s(%d) name=%s data=%d" % \
		(node.product_name, node.node_id, value.label, value.data))

def louie_network_started(network):
	dbg("network is started: homeid %0.8x" % network.home_id)

def louie_network_resetted(network):
	dbg("network is resetted")

def louie_network_ready(network):
	dbg("network is now ready")
	dispatcher.connect(louie_value, ZWaveNetwork.SIGNAL_VALUE)

#
# HTTP related functions
#

class myHandler(BaseHTTPRequestHandler):
	# Disable standard logging messages
	def log_message(self, format, *args):
		return
	
	# Handler for the GET requests
	def do_GET(self):
		if self.path == "/":
			self.path = "/house.html"
		elif self.path == "/get":
			#dbg("serving %s..." % self.path)

			# Return the current status in JSON format
			self.send_response(200)
			self.send_header('Content-type', 'application/json')
			self.end_headers()
			self.request.sendall(json.dumps(values))

			return

		# Otherwise try serving a file
		try:
                	# Open the file and send it
                	f = open(os.curdir + os.sep + self.path)
                	self.send_response(200)
                	self.send_header('Content-type', 'text/html')
                	self.end_headers()
                	self.wfile.write(f.read())
                	f.close()
                	dbg("file %s served" % self.path)

		except IOError:
			self.send_error(404, 'File Not Found: %s' % self.path)
                	dbg("file %s not found!" % self.path)

		return

	# Handler for the POST requests
	def do_POST(self):
		if self.path == "/set":
        		# Parse the data posted
			dbg("managing %s..." % self.path)
        		data = cgi.FieldStorage(fp = self.rfile, 
            			headers = self.headers,
				environ = {'REQUEST_METHOD':'POST',
					 'CONTENT_TYPE':self.headers['Content-Type'],})

			self.send_response(200)
			self.end_headers()
			dbg("got label=%s" % data["do"].value)

			# Set the device according to user input
			if data["do"].value == "switch":
				network.nodes[sw_node].set_switch(sw_val,
					False if values["switch"] == "on" else True)

			return

		# Otherwise retur error
		self.send_error(404, 'File Not Found: %s' % self.path)
               	dbg("file %s not found!" % self.path)

		return			

#
# Usage
#

def usage():
        print("usage: ", NAME, " [-h] [-d] [-l] <dev>", file=sys.stderr)
        print("    -h    - show this message", file=sys.stderr)
        print("    -d    - enable debugging messages", file=sys.stderr)
        print("    -l    - log on stderr", file=sys.stderr)

        sys.exit(1)

#
# Main
#

try:
        opts, args = getopt.getopt(sys.argv[1:], "hdl")
except getopt.GetoptError, err:
        print(str(err), file=sys.stderr)
        usage()

for o, a in opts:
        if o in ("-h", "--help"):
                usage()
        elif o in ("-d"):
                debug = True
        elif o in ("-l"):
                logstderr = True
        else:
                assert False, "unhandled option"

# Check command line
if len(args) < 1:
        usage()
device = args[0]

# Open the communication with syslogd
loglevel = syslog.LOG_PID
if logstderr:
        loglevel |= syslog.LOG_PERROR
syslog.openlog(NAME, loglevel, syslog.LOG_USER)

# Define some manager options and create a network object
options = ZWaveOption(device, config_path = "./openzwave/config",
			user_path = ".", cmd_line = "")
options.set_log_file(NAME + ".log")
options.set_append_log_file(False)
#options.set_console_output(True)
options.set_console_output(False)
options.set_save_log_level(log)
options.set_logging(True)
options.lock()
network = ZWaveNetwork(options, log = None)

# Add the basic callbacks
dispatcher.connect(louie_network_started,
			ZWaveNetwork.SIGNAL_NETWORK_STARTED)
dispatcher.connect(louie_network_resetted,
			ZWaveNetwork.SIGNAL_NETWORK_RESETTED)
dispatcher.connect(louie_network_ready,
			ZWaveNetwork.SIGNAL_NETWORK_READY)
dbg("callbacks installed")

info("Starting...")

# Waiting for driver to start
for i in range(0, timeout_s):
	if network.state >= network.STATE_STARTED:
		break
	else:
		sys.stdout.flush()
		time.sleep(1.0)
if network.state < network.STATE_STARTED:
	err("Can't initialise driver! Look at the logs file")
        sys.exit(1)

info("use openzwave library   = %s" % network.controller.ozw_library_version)
info("use python library      = %s" % network.controller.python_library_version)
info("use ZWave library       = %s" % network.controller.library_description)
info("network home id         = %s" % network.home_id_str)
info("controller node id      = %s" % network.controller.node.node_id)
info("controller node version = %s" % (network.controller.node.version))

# Waiting for network is ready
time_started = 0
for i in range(0, timeout_s):
        if network.state >= network.STATE_READY:
                break
        else:
                time_started += 1
                sys.stdout.flush()
                time.sleep(1.0)

dbg("detecting the switch node...")
for node in network.nodes:
	for val in network.nodes[node].get_switches():
		data = network.nodes[node].values[val].data
		values["switch"] = "on" if data else "off"
		sw_node = node
		sw_val = val
		dbg(" - device %s(%s) is %s" % \
				(network.nodes[node].values[val].label,
			 	node,
			 	values["switch"]))

		# We can manage just one switch!
		break

info("Press CTRL+C to stop")

# Create a web server and define the handler to manage the incoming requests
try:
	server = HTTPServer(('', port), myHandler)
	info("Started HTTP server on port %d" % port)
	
	# Wait forever for incoming HTTP requests
	server.serve_forever()

except KeyboardInterrupt:
	info("CTRL+C received, shutting down...")
	server.socket.close()
	network.stop()

info("Done.")
