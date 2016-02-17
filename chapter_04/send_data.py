#!/usr/bin/python

import gspread
import json
from oauth2client.client import SignedJwtAssertionCredentials

from xml.dom import minidom
import csv

#
# Get connected with Google Docs
#

# Load the credentials
json_key = json.load(open('Project-9a372e9e20e6.json'))
scope = ['https://spreadsheets.google.com/feeds']
credentials = SignedJwtAssertionCredentials(json_key['client_email'], json_key['private_key'], scope)

# Ask for authorization
gc = gspread.authorize(credentials)

# Open the "bbb_weather" spreadsheet
sh = gc.open("bbb_weather")

# Select the worksheet named "BBB wheater"
wks = sh.worksheet("BBB wheater")

#
# Send data to Google Docs
#

# Parse the XML file holding the current weather status
xmldoc = minidom.parse('/var/lib/wfrog/wfrog-current.xml')

# Extract the data
time_obj = xmldoc.getElementsByTagName('time')
time = time_obj[0].firstChild.nodeValue
press_obj = xmldoc.getElementsByTagName('pressure')
press = float(press_obj[0].firstChild.nodeValue)
temp_obj = xmldoc.getElementsByTagName('temp')
temp = float(temp_obj[0].firstChild.nodeValue)
hum_obj = xmldoc.getElementsByTagName('humidity')
hum = float(hum_obj[0].firstChild.nodeValue)
print "current: %s press=%f temp=%f hum=%f" % (time, press, temp, hum)

# Update the current status
wks.update_acell('A3', time)
wks.update_acell('B3', press)
wks.update_acell('C3', temp)
wks.update_acell('D3', hum)

# Parse the CSV file holding the old weather statuses
csvfile = open('/var/lib/wfrog/wfrog.csv', 'rb')
reader = csv.reader(csvfile, delimiter=',')

# Skip the headers
headers = reader.next()

# Find the "LAST" string where to insert data to
last = wks.find("LAST").row - 7
print "last saved row was %d" % last

# Skip already read row
for i in range(0, last):
	dummy = reader.next()

# Start saving not yet saved data
for row in reader:
	time = row[1]
	press = float(row[11])
	temp = float(row[2])
	hum = float(row[3])
	print "old: %s press=%f temp=%f hum=%f" % (time, press, temp, hum)

	# Add a new line with an old status
	wks.insert_row([time, press, temp, hum], 7 + last)
	last += 1
