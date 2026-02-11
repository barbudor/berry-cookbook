import mqtt
import string

# =========================================================

class Device
    var remote_topic, name, power_topic

    def init(device_name, remote_device, power_idx)
        self.name = device_name
        if remote_device != nil
            self.remote_topic = string.replace(tasmota.cmd("FullTopic")['FullTopic'], "%topic%", remote_device)
        else
            self.remote_topic = nil
        end
        if power_idx # not 0 nor nil
            self.power_topic = f"POWER{power_idx}"
        else
            self.power_topic = "POWER"
        end
    end

    def power()
        return self.power_topic
    end

    def make_topic(prefix, cmd)
        return string.replace(self.remote_topic, "%prefix%", prefix) + cmd
    end

    def send_command(cmd, value)
        if value == nil
            value = ''
        end
        if self.remote_topic == nil
            tasmota.cmd(f"backlog0 {cmd} {value}")
        else
            mqtt.publish(self.make_topic("cmnd", cmd), f"{value}")
        end
    end

    def subscribe(prefix, topic, function)
        var subscribe_topic = self.make_topic(prefix, topic)
        #print(f"subscribe to {subscribe_topic}")
        mqtt.subscribe(subscribe_topic, function)
    end
end

# =========================================================

return Device
