#!/usr/bin/env python

import signal
import daemon
import sys
from subprocess import call
from time import sleep
import logging
from smartcard.CardMonitoring import CardMonitor, CardObserver
from smartcard.util import *

logging.basicConfig(level = logging.INFO)

t_cmd = "t"
t_arg = "update"

# The known IDs
ID2NAME = {
	'11 11 11 11 11 11 11 11 11 11 11 11 11 11 11 11 11 11 11': "user1",
	'22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22 22': "user2",
	'3B BE 11 00 00 41 01 38 00 00 00 00 00 00 00 00 01 90 00': 'Rodolfo Giometti'
}

#
# Signals handler
#

def sig_handler(sig, frame):
	sys.exit(0)

#
# Smart Card Observer
#

class printobserver(CardObserver):
	def update(self, observable, (addedcards, removedcards)):
		for card in addedcards:
			try:
				id = toHexString(card.atr)
			except:
				pass
			if len(id) == 0:
				continue
			logging.info("got tag ID " + id)

			# Verify that the tag ID is known and then
			# tweet the event
			try:
				name = ID2NAME[id]
			except:
				logging.info("unknow tag ID! Ignored")
				continue
	
			logging.info("Twitting that " + name + " was arrived!")
			call([t_cmd, t_arg, name + " was arrived!"])

#
# The daemon body
#

def daemon_body():
	# The main loop
	try:
		cardmonitor = CardMonitor()
		cardobserver = printobserver()
		cardmonitor.addObserver(cardobserver)

		while True:
			sleep(1000000) # sleep forever

	except:
		cardmonitor.deleteObserver(cardobserver)

#
# Main
#

# Define the daemon context and install the signals traps
context = daemon.DaemonContext(
	detach_process = False,
	stdout = sys.stdout,
	stderr = sys.stderr,
)
context.signal_map = {
	signal.SIGTERM: sig_handler,
	signal.SIGINT: sig_handler,
}

# Start the daemon
with context:
	daemon_body()

sys.exit(0)
