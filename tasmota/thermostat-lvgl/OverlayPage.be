import BasePage
import string
import json

# =========================================================

class OverlayPage : BasePage

    var current_page_name, device

    def init(page_id, device)
        super(self).init(page_id, "overlay_page", device)
        self.current_page_name = nil
        self.widget['lb_device_name'].text = device.name
        for page_name: ["main_page", "schedule_page", "settings_page"]
            self.widget[f"im_{page_name}"].set_src(f"A:/{page_name}.png")
            self.register_event(f"bt_{page_name}", "down", / -> self.show_page(page_name))
        end
        self.register_callbacks()
    end

    def add_rules()
        tasmota.add_rule(f"{self.device.power()}#State", /v,t,m -> self.set_power_led(v))
    end

    def subscribe_mqtt()
        self.device.subscribe('stat', self.device.power(), /topic, idx, data, databytes -> self.set_power_led(data))
    end

    def show_page(page_name)
        if self.current_page_name != nil
            self.widget[f"bt_{self.current_page_name}"].border_width = 0
            self.widget[f"im_{self.current_page_name}"].bg_opa = 0
        end
        self.current_page_name = page_name
        self.widget[f"bt_{self.current_page_name}"].border_width = 2
        self.widget[f"im_{self.current_page_name}"].bg_opa = 255
        self.pages[page_name].show()
    end

    def set_power_led(state)
        # print("OverlayPage: power state=", state)
        if state == "ON"
            state = 1
        elif string.startswith(state, "{")
            var json_state = json.load(state)
            state = (json_state.find(self.device.power(), 0) == "ON") ? 1 : 0
        end
        # print("OverlayPage: power state 2=", state)
        self.widget["ld_power"].set_color((state == 1) ? "#FF0000" : "#3465a4")
    end
end

# =========================================================

return OverlayPage
