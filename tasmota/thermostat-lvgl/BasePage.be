import haspmota
import string
import display

# =========================================================

class BasePage
    static var pages = {}
    var page, page_name, widget, device

    def init(page_id, page_name, device)
        self.page = haspmota.lvh_pages[page_id]
        self.page_name = page_name
        BasePage.pages[page_name] = self.page
        self.widget = self.get_named_widgets()
        self.device = device
    end

    def get_widget_by_name(name)
        for widget_id : self.page._obj_id.keys()
            var widget = self.page.get_obj(widget_id)
            if widget != nil && widget.meta == name
                return widget
            end
        end
        return nil
    end

    def get_named_widgets()
        var widgets = {}
        for widget_id : self.page._obj_id.keys()
            var widget = self.page.get_obj(widget_id)
            if widget != nil && widget.meta != nil
                widgets[widget.meta] = widget
            end
        end
        return widgets
    end

    def get_widget_id(name)
        var widget = self.widget.find(name)
        if widget != nil
            return f"p{self.page.id()}b{widget.id}"
        end
        print(f"widget {name} not found on page [self.page_name]")
    end

    def register_callbacks()
        if self.device.remote_topic == nil
            self.add_rules()
        else
            self.subscribe_mqtt()
        end
    end

    def add_rules()
        # To be implemented by subclasses
    end

    def subscribe_mqtt()
        # To be implemented by subclasses
    end

    def update()
        # To be implemented by subclasses
    end

    static def set_dimmer(dimmer)
        display.dimmer(dimmer)
    end

    def register_event(widget_name, action, function)
        var widget = self.widget.find(widget_name)
        if widget == nil
            print(f"Error: widget '{widget_name}' not found for event registration")
            return
        end
        var event
        event = f"hasp#p{self.page.id()}b{widget.id}#event"
        if action != nil && action != ""
            event = event + f"={action}"
        end
        # print(f"page {self.page_name} register event {event}")
        tasmota.add_rule(event, function)
    end
end

# =========================================================

return BasePage
