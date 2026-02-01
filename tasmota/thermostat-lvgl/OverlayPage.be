import BasePage

class OverlayPage : BasePage
    var current_page
    static var page_button = [nil, p0b22, p0b32, p0b42]
    static var page_icon = [nil, p0b21, p0b31, p0b41]

    def init(device_name)
        super(self).init(0, p0)
        self.current_page = 1
        p0b11.text = device_name
        self.page_icon[1].set_src("A:/temperature.png")
        self.page_icon[2].set_src("A:/schedule.png")
        self.page_icon[3].set_src("A:/temp_settings.png")       
        tasmota.add_rule("hasp#p0b22#event=down", / -> self.show_page(1))
        tasmota.add_rule("hasp#p0b32#event=down", / -> self.show_page(2))
        tasmota.add_rule("hasp#p0b42#event=down", / -> self.show_page(3))
    end
    
    def show_page(page_id)
        self.page_button[self.current_page].border_width = 0
        self.page_icon[self.current_page].bg_opa = 0
        self.pages[page_id].show()
        self.current_page = page_id
        self.page_button[self.current_page].border_width = 2
        self.page_icon[self.current_page].bg_opa = 255
    end
    
    def set_power_led(state)
        print("power state=", state)
        p0b51.set_color(state ? "#FF0000" : "#3465a4")
    end
end

return OverlayPage
