import math
import persist

import BasePage

class SettingsPage : BasePage
    static var slider_to_label = {
        "p3b24": p3b22,
        "p3b34": p3b32,
        "p3b44": p3b42,
        "p3b54": p3b52,
    }
    static var slider_to_setting = {
        "p3b24": "temp_eco",
        "p3b34": "temp_comfort",
        "p3b44": "temp_comfort_plus",
        "p3b54": "backlight",
    }
    static var backlight_min = 30
    static var backlight_max = 60
    
    def init()
        super(self).init(3, p3)
        tasmota.add_rule("hasp#p3b24#event=changed", /v,t,m -> self.slider_temp_changed(m['hasp']))
        tasmota.add_rule("hasp#p3b34#event=changed", /v,t,m -> self.slider_temp_changed(m['hasp']))
        tasmota.add_rule("hasp#p3b44#event=changed", /v,t,m -> self.slider_temp_changed(m['hasp']))
        tasmota.add_rule("hasp#p3b54#event=changed", /v,t,m -> self.slider_backlight_changed(m['hasp']))
        tasmota.add_rule("hasp#p3b24#event=released", /v,t,m -> self.slider_released(m['hasp']))
        tasmota.add_rule("hasp#p3b34#event=released", /v,t,m -> self.slider_released(m['hasp']))
        tasmota.add_rule("hasp#p3b44#event=released", /v,t,m -> self.slider_released(m['hasp']))
        tasmota.add_rule("hasp#p3b54#event=released", /v,t,m -> self.slider_released(m['hasp']))
    end
    
    def slider_temp_changed(event)
        for slider: event.keys()
            var val = real(event[slider]['val'])/2.0
            var val_str = f"{val:2.1f}"
            var label = self.slider_to_label[slider]
            if label
                label.text = val_str
                persist.setmember(self.slider_to_setting[slider], val)
            end
        end
    end

    def slider_backlight_changed(event)
        for slider: event.keys()
            var val = event[slider]['val']
            var val_str = f"{val:2i}"
            var label = self.slider_to_label[slider]
            if label
                label.text = val_str
                persist.setmember(self.slider_to_setting[slider], val)
                self.set_dimmer(self.backlight_to_dimmer(val))
            end
        end
    end
    
    def slider_released(event)
        persist.save()
    end
    
    def backlight_to_dimmer(slider_val)
        var dimmer = int(math.round(self.backlight_min + (slider_val - 1) / 9.0 * (self.backlight_max - self.backlight_min)))
        return dimmer
    end
    
    def update()
        p3b22.text = f"{persist.temp_eco:2.1f}"
        p3b24.set_val(2*persist.temp_eco)
        p3b32.text = f"{persist.temp_comfort:2.1f}"
        p3b34.set_val(2*persist.temp_comfort)
        p3b42.text = f"{persist.temp_comfort_plus:2.1f}"
        p3b44.set_val(2*persist.temp_comfort_plus)
        p3b52.text = f"{persist.backlight:2i}"
        p3b54.set_val(persist.backlight)
        self.set_dimmer(self.backlight_to_dimmer(persist.backlight))
    end
end

return SettingsPage
