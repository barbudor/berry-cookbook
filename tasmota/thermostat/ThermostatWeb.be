import persist
import webserver

# =========================================================

class ThermostatWeb

    var th
    var last_target_temp

    def init(thermostat_instance)
        self.th = thermostat_instance
        self.last_target_temp = nil
    end

    def slider_update(id, value)
        # This trick allows DOM updates, while <script> tags would be blocked for security reasons
        return f"<img src='data:x,' style='display:none' onerror=\"let obj=eb('{id}');if (obj) obj.{value=};this.remove();\">"
    end


    def web_add_main_button()
        var th_status = self.th.get_status()
        var button_config = "<td style=\"width:33.33%%\"><button onclick='la(\"&m_mode_%s=1\");'>%s</button></td>"
        webserver.content_send("<p></p><center><table style='width:100%'><tbody><tr>")
        webserver.content_send(format(button_config, "eco", "Éco/Manuel"))
        webserver.content_send(format(button_config, "comfort", "Confort"))
        webserver.content_send(format(button_config, "comfortplus", "Confort +"))
        webserver.content_send(f"</tr><tr><td colspan='3' style='width:100%'><div id='s' class='r slider-wrapper' style='background: linear-gradient(to right, rgb(26, 77, 255),rgb(255, 144, 26), rgb(255, 77, 0));'><input id='sltargettemp' name='sltargettemp' type='range' min=8 max=22 step=0.5 value='{th_status['target_temp']}' onchange='la(\"&sltargettemp=\"+value.toString())'><div id='sliderBubble' class='slider-bubble'></div></div></td>")
        webserver.content_send("</tr></tbody></table></center>")
        webserver.content_send(
            "<style>.slider-wrapper{position:relative;width:100%;}"..
            'input[type="range"]{width:100%;}.slider-bubble{position:absolute;top:-45px;width:40px;height:40px;background:#1a4dff;color:white;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:14px;pointer-events:none;opacity:0;transform:translateX(-50%);transition:opacity 0.15s ease;}</style>'..
            '<script>const slider=eb("sltargettemp");const bubble=eb("sliderBubble");function updateBubble(){const min=slider.min;const max=slider.max;const val=slider.value;const percent=(val-min)/(max-min);const sliderRect=slider.getBoundingClientRect();const wrapperRect=slider.parentElement.getBoundingClientRect();const thumbWidth=20;const usableWidth=sliderRect.width-thumbWidth;'..
            'const left=(sliderRect.left-wrapperRect.left)+thumbWidth/2+percent*usableWidth;bubble.textContent=val;bubble.style.left=`${left}px`;}'..
            'slider.addEventListener("input",()=>{bubble.style.opacity=1;updateBubble();});slider.addEventListener("change",()=>{bubble.style.opacity=0;});slider.addEventListener("touchend",()=>{bubble.style.opacity=0;});</script>'
        )
    end

    def web_sensor()
        # for i: 0 .. webserver.arg_size() - 1
        #     print(f"Arg {i}: {webserver.arg_name(i)} = {webserver.arg(i)}")
        # end
        if webserver.has_arg("m_mode_eco")
            tasmota.cmd(f"thpreset eco")
        elif webserver.has_arg("m_mode_comfort")
            tasmota.cmd(f"thpreset comfort")
        elif webserver.has_arg("m_mode_comfort_plus")
            tasmota.cmd(f"thpreset comfortplus")
        elif webserver.has_arg("sltargettemp")
            # print(f"ThWeb: Setting target temp to {webserver.arg('sltargettemp')}")
            tasmota.cmd(f"thtargettemp {webserver.arg('sltargettemp')}")
        end

        var th_status = self.th.get_status()
        var current_temp = (th_status['current_temp'] != nil) ? f"{th_status['current_temp']:.1f}" : "--.-"
        var until_str = "--:--"
        if th_status['preset_until'] > 0
            var tz_diff = tasmota.rtc()['timezone'] * 60
            var until_local = th_status['preset_until'] + tz_diff
            until_str = tasmota.strftime("%H:%M", until_local)
        end
        var mode = "Éco/Manuel"
        var preset = th_status['preset']
        if preset == "comfort"
            mode = "Confort"
        elif preset == "comfortplus"
            mode = "Confort +"
        end

        var msg = f"{{s}}Température courante{{m}}{current_temp} °C{{e}}"..
                  f"{{s}}Température attendue{{m}}<output = id='targettemp'>{th_status['target_temp']:.1f}</output> °C{{e}}"..
                  f"{{s}}Mode{{m}}{mode}{{e}}"..
                  f"{{s}}Jusqu'à{{m}}{until_str}{{e}}"..
                  f"{{s}}Température éco{{m}}{th_status['temp_eco']:.1f} °C{{e}}"..
                  f"{{s}}Température confort{{m}}{th_status['temp_comfort']:.1f} °C{{e}}"..
                  f"{{s}}Température confort +{{m}}{th_status['temp_comfortplus']:.1f} °C{{e}}"
        tasmota.web_send_decimal(msg)
        if th_status['target_temp'] != self.last_target_temp
            self.last_target_temp = th_status['target_temp']
            tasmota.web_send(self.slider_update('sltargettemp', self.last_target_temp))
        end

    end

end

# =========================================================

return ThermostatWeb
