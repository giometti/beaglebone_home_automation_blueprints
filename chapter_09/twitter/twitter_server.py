#!/usr/bin/python

from __future__ import print_function
import os
import sys
import time
import getopt
import syslog
import signal
import socket
import daemon
import ../../lib/logging.py

NAME = os.path.basename(sys.argv[0])

debug = False
daemonize = True
logstderr = False
socket_file = "/tmp/" + NAME + ".sock"

#
# Signals handler
#

def sig_handler(sig, frame):
	dbg("signal trapped!")
	sys.exit(0)

#
# The daemon body
#

def daemon_body(sock):
	# The main loop
	dbg("start main loop")
	while True:
		dbg("wait for a connection")
		conn, addr = sock.accept()

    		try:
        		print >>sys.stderr, 'connection from', addr

        		# Receive the data in small chunks and retransmit it
        while True:
            data = connection.recv(16)
            print >>sys.stderr, 'received "%s"' % data
            if data:
                print >>sys.stderr, 'sending data back to the client'
                connection.sendall(data)
            else:
                print >>sys.stderr, 'no more data from', client_address
                break
            
    finally:
        # Clean up the connection
        connection.close()

#
# Usage
#

def usage():
	print("usage: ", NAME, " [-h] [-d] [-f] [-l]", file=sys.stderr)
	print("    -h    - show this message", file=sys.stderr)
	print("    -d    - enable debugging messages", file=sys.stderr)
	print("    -f    - do not daemonize", file=sys.stderr)
	print("    -l    - log on stderr", file=sys.stderr)

	sys.exit(1)

#
# Main
#

# Check the command line
try:
	opts, args = getopt.getopt(sys.argv[1:], "hdfl")
except getopt.GetoptError, err:
	print(str(err), file=sys.stderr)
	usage()

for o, a in opts:
	if o in ("-h"):
		usage()
	elif o in ("-d"):
		debug = True
	elif o in ("-f"):
		daemonize = False
	elif o in ("-l"):
		logstderr = True
	else:
		assert False, "unhandled option"

# Open the communication with syslogd
loglevel = syslog.LOG_PID
if logstderr:
	loglevel |= syslog.LOG_PERROR
syslog.openlog(NAME, loglevel, syslog.LOG_USER)

# Make sure the socket does not already exist and then create the socket,
# bind it with the file and then start listening for incoming connections
try:
	os.unlink(socket_file)

except OSError:
	if os.path.exists(socket_file):
		err(str(err))
		sys.exit(1)

sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
sock.bind(socket_file)
sock.listen(4)		# we use a queue of #clients + 1

# Define the daemon context and install the signals traps
context = daemon.DaemonContext(
	detach_process = daemonize,
)
context.signal_map = {
	signal.SIGTERM: sig_handler,
	signal.SIGINT: sig_handler,
}
dbg("signals traps installed")

# Start the daemon
with context:
	daemon_body(sock)

sys.exit(0)
