import mqtt
import json

import Thermostat
th = Thermostat(0)
mqtt.subscribe('tele/blegateway/pte_piece', /full_topic, idx, data, databytes -> th.set_temp(json.load(data).find('Temperature')))

import ThermostatWeb
tw = ThermostatWeb(th)

tasmota.add_driver(th)
tasmota.add_driver(tw)
