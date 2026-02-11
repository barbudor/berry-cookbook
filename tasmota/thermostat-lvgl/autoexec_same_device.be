import mqtt
import json

import Thermostat
th = Thermostat(0)
mqtt.subscribe('tele/blegateway/cuisine', /full_topic, idx, data, databytes -> tasmota.cmd(f"THSetTemp {json.load(data).find('Temperature')}"))

import ThermostatWeb
tw = ThermostatWeb(th)

tasmota.add_driver(th)
tasmota.add_driver(tw)


import haspmota
haspmota.start()

import Device
import OverlayPage
import MainPage
#import SchedulePage
import SettingsPage

var device_name = tasmota.cmd("DeviceName")['DeviceName']
var device = Device(device_name)
var overlay_page = OverlayPage(0, device)
var main_page = MainPage(1, device)
#var schedule_page = SchedulePage(2, device)
var settings_page = SettingsPage(3, device)
overlay_page.show_page("main_page")

device.send_command("Thermostat")

print("autoexec completed")
