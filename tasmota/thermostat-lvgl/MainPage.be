import math
import persist
import haspmota

import BasePage

class MainPage : BasePage
    static var bat_color = ["#FF0000", "#FF6A00", "#FFD800", "#3DCC00"]
    static var bat_icon = ["\uE08E", "\uF2A1", "\uF2A2", "\uF2A3"]
    static var event_map = {
        "temp_up": "hasp#p1b41#event=down",
        "temp_dn": "hasp#p1b42#event=down",
        "conf+":   "hasp#p1b21#event=down", 
        "conf":    "hasp#p1b22#event=down", 
        "eco":     "hasp#p1b23#event=down",        
    }

    def init()
        super(self).init(1, p1)
    end
    
    def update_target_temp_block()
        p1b32.text = f"{persist.target_temp:2.1f}"
        if persist.preset_until == 0
            p1b33.text = ""
        else
            var preset_local = tasmota.time_dump(persist.preset_until)
            p1b33.text = f"jusqu'a {preset_local['hour']:02i}:{preset_local['min']:02i}"
        end
    end
    
    def update_sensor_block(current_temp, current_hum, battery_level)
        var battery_idx = math.min(int(battery_level / 25), 3)
        p1b52.text = f"{current_temp:2.1f}"
        p1b57.text = f"{current_hum:2.1f}"
        p1b54.text = self.bat_icon[battery_idx]
        p1b54.text_color = self.bat_color[battery_idx]
        p1b59.text = f"{battery_level:2i}"
        p1b59.text_color = self.bat_color[battery_idx]
    end
    
    def update()
        super(self).update()
        self.update_target_temp_block()
    end
end

return MainPage
