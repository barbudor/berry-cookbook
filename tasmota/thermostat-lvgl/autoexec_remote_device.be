tasmota.set_power(0,true) # insure display is on early (pb when using so0 0)
import haspmota
haspmota.start()

import Device
import OverlayPage
import MainPage
#import SchedulePage
import SettingsPage

var device = Device("Chauffage Bureau", "htr-smallroom", 0)
var overlay_page = OverlayPage(0, device)
var main_page = MainPage(1, device)
#var schedule_page = SchedulePage(2, device)
var settings_page = SettingsPage(3, device)
overlay_page.show_page("main_page")

tasmota.add_rule("mqtt#connected", / -> device.send_command("Thermostat"))

print("autoexec completed")
