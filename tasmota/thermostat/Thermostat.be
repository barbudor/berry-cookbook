import math
import persist
import json
import string

# =========================================================

class Thermostat
    static var MIN_TEMP = 8
    static var MAX_TEMP = 25
    static var UNTIL_STEP = 30 * 60
    static var PERIOD = 5
    static var LOG_LEVEL_NONE=0
    static var LOG_LEVEL_ERROR=1
    static var LOG_LEVEL_INFO=2
    static var LOG_LEVEL_DEBUG=3
    static var LOG_LEVEL_DEBUG_MORE=4

    var power_index,current_temp, period, temp_timeout

    def init(power_index)
        self.persist_init("target_temp", 14.0)
        self.persist_init("temp_eco", 14.0)
        self.persist_init("temp_comfort", 18.0)
        self.persist_init("temp_comfort_plus", 19.5)
        self.persist_init("preset", "eco")
        self.persist_init("preset_until", 0)
        persist.save()
        self.power_index = power_index  # 0 == Power1, 1 = Power2, ...
        self.current_temp = nil
        self.temp_timeout = 0
        self.period = 1
        tasmota.add_cmd("THSetTemp", /cmd, idx, payload, payload_json -> self.cmnd_set_temp(cmd, idx, payload, payload_json))
        tasmota.add_cmd("THTargetTemp", /cmd, idx, payload, payload_json -> self.cmnd_target_temp(cmd, idx, payload, payload_json))
        tasmota.add_cmd("THTempEco", /cmd, idx, payload, payload_json -> self.cmnd_temp_eco(cmd, idx, payload, payload_json))
        tasmota.add_cmd("THTempComfort", /cmd, idx, payload, payload_json -> self.cmnd_temp_comfort(cmd, idx, payload, payload_json))
        tasmota.add_cmd("THTempComPlus", /cmd, idx, payload, payload_json -> self.cmnd_temp_complus(cmd, idx, payload, payload_json))
        tasmota.add_cmd("THPreset", /cmd, idx, payload, payload_json -> self.cmnd_preset(cmd, idx, payload, payload_json))
        tasmota.add_cmd("Thermostat", /cmd, idx, payload, payload_json -> self.cmnd_th(cmd, idx, payload, payload_json))
        tasmota.add_cron("0 * * * * *", / -> self.every_min(), "every_min")
    end

    def set_debug(max_level)
        Thermostat.LOG_LEVEL_NONE = (max_level >= 0) ? 0 : max_level
        Thermostat.LOG_LEVEL_ERROR = (max_level >= 1) ? 1 : max_level
        Thermostat.LOG_LEVEL_INFO = (max_level >= 2) ? 2 : max_level
        Thermostat.LOG_LEVEL_DEBUG = (max_level >= 3) ? 3 : max_level
        Thermostat.LOG_LEVEL_DEBUG_MORE = (max_level >= 4) ? 4 : max_level
    end

    def persist_init(key, default)
        if !persist.has(key)
            persist.setmember(key, default)
        end
    end

    def str_to_temp(payload)  # -> real
        var temp = math.round(real(payload) * 2.0) / 2.0
        return temp
    end

    def valid_temp(temp)  # -> boolean
        if (temp < self.MIN_TEMP) || (temp > self.MAX_TEMP)
            tasmota.log(f"Thermostat: temp {temp} out of range", self.LOG_LEVEL_ERROR)
            return false
        end
        return true
    end

    def cmnd_th(cmd, idx, payload, payload_json)
        var error = false
        if payload != ''
            if type(payload_json) == "instance"
                if error := (payload_json.has('targettemp') && payload_json.has('preset') && payload_json['preset'] != "eco")
                    tasmota.log("Thermostat: cannot set targettemp and preset at the same time", self.LOG_LEVEL_ERROR)
                end
                if !error && payload_json.has('current_temp')
                    error = !self.set_temp(self.str_to_temp(payload_json['current_temp']))
                end
                if !error && payload_json.has('target_temp')
                    error = !self.set_target_temp(self.str_to_temp(payload_json['target_temp']), true)
                end
                if !error && payload_json.has('temp_eco')
                    error = !self.set_temp_eco(self.str_to_temp(payload_json['temp_eco']))
                end
                if !error && payload_json.has('temp_comfort')
                    error = !self.set_temp_comfort(self.str_to_temp(payload_json['temp_comfort']))
                end
                if !error && payload_json.has('temp_comfort_plus')
                    error = !self.set_temp_comfort_plus(self.str_to_temp(payload_json['temp_comfort_plus']))
                end
                if !error && payload_json.has('preset')
                    error = !self.set_target_temp_preset(payload_json['preset'])
                end
            end
        end
        if error
            tasmota.resp_cmnd_error()
        else
            tasmota.resp_cmnd(json.dump({'Thermostat': self.get_status()}))
        end
    end

    def get_status()  # -> instance
        var until_iso = (persist.preset_until > 0) ? tasmota.time_str(persist.preset_until) + "Z" : nil
        return {
            'current_temp': self.current_temp,
            'target_temp': persist.target_temp,
            'temp_eco': persist.temp_eco,
            'temp_comfort': persist.temp_comfort,
            'temp_comfort_plus': persist.temp_comfort_plus,
            'preset': persist.preset,
            'preset_until': persist.preset_until,
            'preset_until_iso': until_iso
        }
    end

    def get(param)
        if param == "current_temp"
            return self.current_temp
        end
        return persist.find(param)
    end

    def json_append()
        tasmota.response_append(",\"Thermostat\":"+json.dump(self.get_status()))
    end

    def cmnd_set_temp(cmd, idx, payload, payload_json)
        if payload != ''
            self.set_temp(self.str_to_temp(payload))
        end
        tasmota.resp_cmnd(f"{self.current_temp:.1f}")
    end

    def set_temp(new_temp)  # -> boolean
        self.current_temp = new_temp
        if self.temp_timeout == 0
            tasmota.log("Thermostat: temp recovered", self.LOG_LEVEL_INFO)
        end
        self.temp_timeout = 2 * self.PERIOD + 1
        return true
    end

    def cmnd_target_temp(cmd, idx, payload, payload_json)
        if payload != '' && !self.set_target_temp(self.str_to_temp(payload), true)
            tasmota.resp_cmnd_error()
            return
        end
        tasmota.resp_cmnd(f"{persist.target_temp:.1f}")
    end

    def set_target_temp(new_temp, force)  # -> boolean
        # print(f"update target_temp={new_temp} force={force}")
        if force || (persist.preset_until == 0)
            persist.target_temp = math.min(math.max(self.MIN_TEMP, new_temp), self.MAX_TEMP)
            print(f"set target_temp {new_temp}=>{persist.target_temp}")
            persist.save()
            return true
        end
        tasmota.log("Thermostat: preset active, target temp change ignored", self.LOG_LEVEL_INFO)
        self.period = 1  # immediate regulation
        return false
    end

    def cmnd_temp_eco(cmd, idx, payload, payload_json)
        if payload != '' && !self.set_temp_eco(self.str_to_temp(payload))
            tasmota.resp_cmnd_error()
            return
        end
        tasmota.resp_cmnd(f"{persist.temp_eco:.1f}")
    end

    def set_temp_eco(new_temp)  # -> boolean
        if self.valid_temp(new_temp)
            persist.temp_eco = new_temp
            print(f"preset={persist.preset}, new_temp={new_temp}")
            persist.save()
            return true
        end
    end

    def cmnd_temp_comfort(cmd, idx, payload, payload_json)
        if payload != '' && !self.set_temp_comfort(self.str_to_temp(payload))
            tasmota.resp_cmnd_error()
            return
        end
        tasmota.resp_cmnd(f"{persist.temp_comfort:.1f}")
    end

    def set_temp_comfort(new_temp)  # -> boolean
        if self.valid_temp(new_temp)
            persist.temp_comfort = new_temp
            persist.save()
            return true
        end
    end

    def cmnd_temp_complus(cmd, idx, payload, payload_json)
        if payload != '' && !self.set_temp_comfort_plus(self.str_to_temp(payload))
            tasmota.resp_cmnd_error()
            return
        end
        tasmota.resp_cmnd(f"{persist.temp_comfort_plus:.1f}")
    end

    def set_temp_comfort_plus(new_temp)  # -> boolean
        if self.valid_temp(new_temp)
            persist.temp_comfort_plus = new_temp
            persist.save()
            return true
        end
    end

    def cmnd_preset(cmd, idx, payload, payload_json)
        if payload != '' && !self.set_target_temp_preset(payload)
            tasmota.resp_cmnd_error()
            return
        end
        tasmota.resp_cmnd(json.dump({'Thermostat': self.get_status()}))
    end

    def set_target_temp_preset(preset)  # -> boolean
        # print(f"set preset={preset}")
        if preset != "eco" && preset != "comfort" && preset != "comfortplus"
            tasmota.log(f"Thermostat: invalid preset {preset}", self.LOG_LEVEL_ERROR)
            return false
        end
        persist.preset = preset
        if preset == "eco"
            persist.preset_until = 0
            self.set_target_temp(persist.temp_eco, true)
        else
            if persist.preset_until == 0
                var now = tasmota.time_dump(tasmota.rtc()['utc'])
                var now_round_min = int(60 * int(now['epoch'] / 60))
                persist.preset_until = now_round_min + 2 * self.UNTIL_STEP
            else
                persist.preset_until += self.UNTIL_STEP
            end
            if preset == "comfort"
                self.set_target_temp(persist.temp_comfort, true)
            else
                self.set_target_temp(persist.temp_comfort_plus, true)
            end
        end
        # print(f"=> target_temp={persist.target_temp}, presetuntil={persist.preset_until}")
        persist.save()
        return true
    end

    def every_min()
        var now = tasmota.time_dump(tasmota.rtc()['utc'])
        # print(f"preset_until={persist.preset_until}, now={now['epoch']}")
        if (persist.preset_until > 0) && (now['epoch'] >= persist.preset_until)
           self.set_target_temp_preset("eco")
        end
        if self.temp_timeout > 0
            self.temp_timeout -= 1
            if self.temp_timeout == 0
                self.current_temp = nil
                tasmota.log("Thermostat: temp timeout", self.LOG_LEVEL_ERROR)
            end
        end
        self.regulate()
    end

    def regulate()
        # very basic temperature regulation
        self.period -= 1
        if self.period == 0
            self.period = self.PERIOD
            if self.temp_timeout > 0
                var diff_temp = persist.target_temp - self.current_temp
                var power_pulse = self.PERIOD * 60000  # minutes => milliseconds
                if diff_temp <= 0
                    tasmota.log(f"Thermostat: diff_temp={diff_temp:.2f}, power off", self.LOG_LEVEL_DEBUG)
                    tasmota.set_power(self.power_index, false)
                else
                    if diff_temp <= 0.5
                        power_pulse = int(math.floor(0.700 * power_pulse))
                    elif diff_temp <= 1.0
                        power_pulse = int(math.floor(0.850 * power_pulse))
                    end
                    tasmota.log(f"Thermostat: diff_temp={diff_temp:.2f}, power_pulse={power_pulse}ms", self.LOG_LEVEL_DEBUG)
                    tasmota.cmd(f"TimedPower{self.power_index+1} {power_pulse+5000:i} ON")
                end
            end
        end
    end
end

# =========================================================

return Thermostat
