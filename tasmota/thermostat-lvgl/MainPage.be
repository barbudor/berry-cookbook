import haspmota
import BasePage
import mqtt
import string
import json

# =========================================================

class MainPage : BasePage
    static var temp_step = 0.5

    var remote_topic, current_temp, target_temp, preset

    def init(page_id, device)
        super(self).init(page_id, "main_page", device)
        self.register_event("bt_temp_up", "down", / -> self.inc_target_temp(self.temp_step))
        self.register_event("bt_temp_down", "down", / -> self.inc_target_temp(-self.temp_step))
        self.register_event("bt_comfortplus", "down", / -> self.set_preset("comfortplus"))
        self.register_event("bt_comfort", "down", / -> self.set_preset("comfort"))
        self.register_event("bt_eco", "down", / -> self.set_preset("eco"))
        self.register_callbacks()
    end

    def add_rules()
        tasmota.add_rule("THSetTemp", /v,t,m -> self.update_temp("current_temp", v))
        tasmota.add_rule("THTargetTemp", /v,t,m -> self.update_temp("target_temp", v))
        tasmota.add_rule("THPreset", /v,t,m -> self.update_thermostat(m['THPreset']))
        tasmota.add_rule("Thermostat", /v,t,m -> self.update_thermostat(m['Thermostat']))
    end

    def subscribe_mqtt()
        self.device.subscribe('stat', "THSETTEMP", /topic, idx, data, databytes -> self.update_temp("current_temp", json.load(data).find('THSetTemp')))
        self.device.subscribe('stat', "THTARGETTEMP", /topic, idx, data, databytes -> self.update_temp("target_temp", json.load(data).find('THTargetTemp')))
        self.device.subscribe('stat', "THPRESET", /topic, idx, data, databytes -> self.update_thermostat(json.load(data)['THPreset']))
        self.device.subscribe('stat', "THERMOSTAT", /topic, idx, data, databytes -> self.update_thermostat(json.load(data)['Thermostat']))
    end

    def inc_target_temp(step)
        # print(f"MainPage: Changing target temp by {step}")
        if (self.preset == "comfort" || self.preset == "comfortplus") && self.target_temp != nil
            var new_temp = self.target_temp + step
            self.device.send_command("THTARGETTEMP", new_temp)
            self.update_temp("target_temp", new_temp)
        end
    end

    def set_preset(new_preset)
        # print("MainPage: button preset to", new_preset)
        self.device.send_command(f"THPRESET", new_preset)
    end

    def update_temp(setting, value)
        if value != nil
            # print(f'MainPage: Updating {setting} to {value}')
            value = real(value)
            self.widget[f"lb_{setting}"].text = f"{value:2.1f}"
            if setting == "target_temp"
                self.target_temp = value
            elif setting == "current_temp"
                self.current_temp = value
            end
        end
    end

    def update_preset_until(value)
        if value != nil
            # print('MainPage: Updating preset until to', value)
            var preset_until = int(value)
            if preset_until == 0
                self.widget['lb_preset_until'].text = ""
            else
                var timezone = 60 * tasmota.rtc()['timezone']
                var preset_local = tasmota.time_dump(preset_until + timezone)
                self.widget['lb_preset_until'].text = f"jusqu'a {preset_local['hour']:02i}:{preset_local['min']:02i}"
            end
        end
    end

    def update_thermostat(th_status)
        # {"preset_until_iso":null,"temp_comfortplus":20,"temp_eco":12,"current_temp":16.8,"temp_comfort":18.5,"preset_until":0,"preset":"eco","target_temp":12}
        # print('MainPage: Updating thermostat data:', th_status)
        var value = th_status.find("current_temp")
        if value != nil
            self.update_temp("current_temp", value)
        end
        value = th_status.find("target_temp")
        if value != nil
            self.update_temp("target_temp", value)
        end
        value = th_status.find("preset")
        if value != nil
            self.preset = value
        end
        value = th_status.find("preset_until")
        if value != nil
            self.update_preset_until(value)
        end
    end
end

# =========================================================

return MainPage
