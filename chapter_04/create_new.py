#!/usr/bin/python

import gspread
import json
from oauth2client.client import SignedJwtAssertionCredentials

# Load the credentials
json_key = json.load(open('Project-9a372e9e20e6.json'))
scope = ['https://spreadsheets.google.com/feeds']
credentials = SignedJwtAssertionCredentials(json_key['client_email'], json_key['private_key'], scope)

# Ask for authorization
gc = gspread.authorize(credentials)

# Open the "bbb_weather" spreadsheet
sh = gc.open("bbb_weather")

# Add a new worksheet named "BBB wheater" with size of 7x4 cells
wks = sh.add_worksheet(title="BBB wheater", rows="7", cols="4")

# Setup the "current status" part
wks.update_acell('A1', 'Current status')

wks.update_acell('A2', 'Time (D h)')
wks.update_acell('B2', 'Pressure (hPa)')
wks.update_acell('C2', 'Temperature (C)')
wks.update_acell('D2', 'Humidity (%)')

# Setup the "old statuses" part
wks.update_acell('A5', 'Old statuses')

wks.update_acell('A6', 'Time (D h)')
wks.update_acell('B6', 'Pressure (hPa)')
wks.update_acell('C6', 'Temperature (C)')
wks.update_acell('D6', 'Humidity (%)')

wks.update_acell('A7', 'LAST')
