import BasePage
import math
import persist
import string
import mqtt
import json

# =========================================================

class SettingsPage : BasePage
    static var setting_to_cmnd = {
        "temp_eco": "ThTempEco",
        "temp_comfort": "ThTempComfort",
        "temp_comfortplus": "ThTempComPlus",
    }
    static var backlight_min = 30
    static var backlight_max = 60
    var remote_topic, slider_cache

    def init(page_id, device)
        super(self).init(page_id, "settings_page", device)
        self.persist_init("backlight", 8)
        self.update_backlight(persist.backlight)
        self.register_event("sl_temp_eco", nil, /v,t,m -> self.slider_event(v, m['hasp'], 'temp_eco'))
        self.register_event("sl_temp_comfort", nil, /v,t,m -> self.slider_event(v, m['hasp'], 'temp_comfort'))
        self.register_event("sl_temp_comfortplus", nil, /v,t,m -> self.slider_event(v, m['hasp'], 'temp_comfortplus'))
        self.register_event("sl_backlight", nil, /v,t,m -> self.slider_backlight_event(v, m['hasp']))
        self.register_callbacks()
    end

    def persist_init(key, default)
        if !persist.has(key)
            persist.setmember(key, default)
        end
    end

    def add_rules()
        tasmota.add_rule("THTempEco", /v,t,m -> self.update_temp_preset("eco", v))
        tasmota.add_rule("THTempComfort", /v,t,m -> self.update_temp_preset("comfort", v))
        tasmota.add_rule("THTempComPlus", /v,t,m -> self.update_temp_preset("comfortplus", v))
        tasmota.add_rule("Thermostat", /v,t,m -> self.update_thermostat(m['Thermostat']))
    end

    def subscribe_mqtt()
        self.device.subscribe('stat', "THTempEco", /topic, idx, data, databytes -> self.update_temp_preset("eco", json.load(data).find('THTempEco')))
        self.device.subscribe('stat', "THTempComfort", /topic, idx, data, databytes -> self.update_temp_preset("comfort", json.load(data).find('THTempComfort')))
        self.device.subscribe('stat', "THTempComPlus", /topic, idx, data, databytes -> self.update_temp_preset("comfortplus", json.load(data).find('THTempComPlus')))
        self.device.subscribe('stat', "THERMOSTAT", /topic, idx, data, databytes -> self.update_thermostat(json.load(data)['Thermostat']))
    end

    def slider_event(event_name, payload, setting_name)
        # print("SettingsPage: slider event:", event_name, payload, setting_name)
        var slider_id = self.get_widget_id(f"sl_{setting_name}")
        if event_name == "changed"
            var val = real(payload[slider_id]['val'])/2.0
            var val_str = f"{val:2.1f}"
            self.slider_cache = val_str
            var label = self.widget.find(f"lb_{setting_name}")
            if label
                label.text = val_str
            end
        elif event_name == "up"
            var cmnd = self.setting_to_cmnd[setting_name]
            if cmnd
                self.device.send_command(cmnd, self.slider_cache)
            end
        end
    end

    def slider_backlight_event(event_name, payload)
        # print("SettingsPage: backlight slider event:", event_name, payload)
        var slider_id = self.get_widget_id("sl_backlight")
        if event_name == "changed"
            var val = payload[slider_id]['val']
            var val_str = f"{val:2i}"
            self.slider_cache = val_str
            var label = self.widget.find("lb_backlight")
            if label
                label.text = val_str
                self.set_dimmer(self.backlight_to_dimmer(val))
            end
        elif event_name == "up"
            persist.backlight = self.slider_cache
            persist.save()
        end
    end

    def backlight_to_dimmer(slider_val)
        var dimmer = int(math.round(self.backlight_min + (slider_val - 1) / 9.0 * (self.backlight_max - self.backlight_min)))
        return dimmer
    end

    def update_temp_preset(preset, value)
        if value != nil
            var temp = real(value)
            self.widget[f"lb_temp_{preset}"].text = f"{temp:2.1f}"
            self.widget[f"sl_temp_{preset}"].set_val(2*temp)
        end
    end

    def update_backlight(value)
        if value != nil
            var backlight = int(value)
            self.widget["lb_backlight"].text = f"{backlight:2i}"
            self.widget["sl_backlight"].set_val(backlight)
            self.set_dimmer(self.backlight_to_dimmer(backlight))
        end
    end

    def update_thermostat(th_status)
        # {"preset_until_iso":null,"temp_comfortplus":20,"temp_eco":12,"current_temp":16.8,"temp_comfort":18.5,"preset_until":0,"preset":"eco","target_temp":12}
        # print('SettingsPage: Updating settings page:', th_status)
        var value = th_status.find("temp_eco")
        if value != nil
            self.update_temp_preset("eco", value)
        end
        value = th_status.find("temp_comfort")
        if value != nil
            self.update_temp_preset("comfort", value)
        end
        value = th_status.find("temp_comfortplus")
        if value != nil
            self.update_temp_preset("comfortplus", value)
        end
    end
end

# =========================================================

return SettingsPage
