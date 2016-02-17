## Copyright 2010 Rodolfo Giometti <giometti@hce-engineering.com>
##                derived from ws23xx by Laurent Bovet
##
##  This file is part of wfrog
##
##  wfrog is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import time
import logging
from wfcommon import units

class BBBhabpStation(object):

    '''
    Station driver for BeagleBone Black Home Automation Blueprints.
      
    [Properties]
    
    period [numeric] (optional):
        Polling interval in seconds. Defaults to 60.    
    '''

    period=60

    logger = logging.getLogger('station.bbb_habp')
    
    name = 'BeagleBone Home Automation Blueprints weather station'

    def get_press(self):
        f = open("/sys/bus/iio/devices/iio:device1/in_pressure_input", "r")
        v = f.read()
        f.close()

        return float(v) * 10.0

    def get_temp(self):
        f = open("/sys/class/hwmon/hwmon0/device/temp1_input", "r")
        v = f.read()
        f.close()

        return int(v) / 1000.0

    def get_hum(self):
        f = open("/sys/class/hwmon/hwmon0/device/humidity1_input", "r")
        v = f.read()
        f.close()

        return int(v) / 1000.0

    def run(self, generate_event, send_event, context={}):
        while True:
            try:
                e = generate_event('press')
                e.value = self.get_press()
                send_event(e)
		self.logger.debug("press=%fhPa" % e.value)
                                
            except Exception, e:
                self.logger.error(e)

            try:
                e = generate_event('temp')
                e.sensor = 0
                e.value = self.get_temp()
                send_event(e)
		self.logger.debug("temp=%fC" % e.value)
                                
            except Exception, e:
                self.logger.error(e)
                
            try:
                e = generate_event('hum')
                e.sensor = 0
                e.value = self.get_hum()
                send_event(e)
		self.logger.debug("hum=%f%%RH" % e.value)
                                
            except Exception, e:
                self.logger.error(e)
                
            try:
                e = generate_event('temp')
                e.sensor = 1
                e.value = self.get_temp()
                send_event(e)
		self.logger.debug("temp=%fC" % e.value)
                                
            except Exception, e:
                self.logger.error(e)
                
            try:
                e = generate_event('hum')
                e.sensor = 1
                e.value = self.get_hum()
                send_event(e)
		self.logger.debug("hum=%f%%RH" % e.value)
                                
            except Exception, e:
                self.logger.error(e)
                
            # pause until next update time
            next_update = self.period - (time.time() % self.period)
            time.sleep(next_update)                
