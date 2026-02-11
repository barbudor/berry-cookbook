import BasePage
import persist

# =========================================================

class SchedulePage : BasePage
    def init(page_id, device)
        super(self).init(page_id, "schedule_page", device)
    end
end

# =========================================================

return SchedulePage
