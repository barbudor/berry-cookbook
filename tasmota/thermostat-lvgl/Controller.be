import math
import json
import mqtt
import persist

# =========================================================
    
class Controller
    static var preset_step = 30 * 60
    static var temp_step = 0.5
    
    var current_temp, overlay_page, main_page, settings_page
    
    def init(overlay_page, main_page, settings_page, sensor_topic)
        self.current_temp = nil
        self._init("target_temp", 14.0)
        self._init("temp_eco", 14.0)
        self._init("temp_comfort", 18.0)
        self._init("temp_comfort_plus", 19.5)
        self._init("preset_until", 0)
        self._init("backlight", 5)
        self._init("power_pulse", 240)
        persist.save()
        self.overlay_page = overlay_page
        self.main_page = main_page
        self.settings_page = settings_page
        main_page.register_event("temp_up", / -> self.inc_target_temp())
        main_page.register_event("temp_dn", / -> self.dec_target_temp())
        main_page.register_event("conf+",   / -> self.set_target_temp_preset(2))
        main_page.register_event("conf",    / -> self.set_target_temp_preset(1))
        main_page.register_event("eco",     / -> self.set_target_temp_preset(0))
        main_page.update()
        settings_page.update()
        tasmota.add_cron("0 * * * * *", / -> self.every_min(), "every_min")
        mqtt.subscribe(sensor_topic, /full_topic, idx, data, databytes -> self.on_sensor_received(full_topic, idx, data, databytes))        
        tasmota.add_rule("power1", /v,t,m -> self.power_changed(m['Power1']['State']))
    end

    def _init(key, default)
        if !persist.has(key) 
            persist.setmember(key, default)
        end
    end  
        
    def update_target_temp(new_temp, force)
        # print(f"update target_temp={new_temp} force={force}")
        if force || (persist.preset_until > 0)
            persist.target_temp = math.min(math.max(12, new_temp), 22)
            persist.save()
            self.main_page.update_target_temp_block()
        end
    end

    def inc_target_temp()
        self.update_target_temp(persist.target_temp + self.temp_step, false)
    end
    
    def dec_target_temp()
        self.update_target_temp(persist.target_temp + self.temp_step, false)
    end

    def set_target_temp_preset(preset)
        # print(f"set preset={preset}")
        if preset == 0
            persist.preset_until = 0
            self.update_target_temp(persist.temp_eco, true)
        else
            if persist.preset_until == 0
                var now_local = tasmota.time_dump(tasmota.rtc()['local'])
                var now_round_min = int(60 * int(now_local['epoch'] / 60))
                persist.preset_until = now_round_min + 2 * self.preset_step
            else
                persist.preset_until += self.preset_step
            end
            if preset == 1
                self.update_target_temp(persist.temp_comfort, true)
            else
                self.update_target_temp(persist.temp_comfort_plus, true)
            end
        end
        # print(f"=> target_temp={persist.target_temp}, presetuntil={persist.preset_until}")
        persist.save()
    end

    def every_min()
        var now_local = tasmota.time_dump(tasmota.rtc()['local'])
        # print(f"preset_until={persist.preset_until}, now={now_local['epoch']}")
        if (persist.preset_until > 0) && (now_local['epoch'] >= persist.preset_until)
           self.set_target_temp_preset(0)
        end
    end

    def on_sensor_received(full_topic, idx, data, databytes)
        # print(f"received={data}")
        var sensor_data = json.load(data)
        self.current_temp = sensor_data.find('Temperature')
        var current_hum = sensor_data.find('Humidity')
        var battery_level = sensor_data.find('Battery')
        self.main_page.update_sensor_block(self.current_temp, current_hum, battery_level)
        # very basic temperature regulation
        var power = (self.current_temp < persist.target_temp) ? "ON" : "OFF"
        tasmota.cmd(f"TimedPower1 {1000 * persist.power_pulse:i},{power}")
    end
    
    def power_changed(power_state)
        self.overlay_page.set_power_led(power_state)
    end
end

# =========================================================

return Controller
