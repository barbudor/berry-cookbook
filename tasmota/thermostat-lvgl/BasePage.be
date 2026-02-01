import display

class BasePage
    static var event_map = {}
    static var pages = {}
    var page_id
    var page
    
    def init(page_id, page)
        self.page_id = page_id
        self.page = page
        self.pages[page_id] = page
    end
    
    def update()
    end
    
    def set_dimmer(dimmer)
        display.dimmer(dimmer)
    end
    
    def register_event(event_name, function)
        var event_rule = self.event_map.find(event_name)
        if event_rule
            tasmota.add_rule(event_rule, function)          
        end
    end
end

return BasePage
