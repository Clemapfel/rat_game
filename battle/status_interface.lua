--- @class bt.StatusInterface
function bt.StatusInterface(scene, entity, status)
    meta.assert_isa(scene, bt.Scene)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.Status)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.StatusInterface"
    metatable.scene = scene
    metatable.entity = entity
    metatable.original = status

    self.get_id = function(self)
        return getmetatable(self).original:get_id()
    end

    self.get_name = function(self)
        return getmetatable(self).original:get_name()
    end

    self.get_max_duration = function(self)
        return getmetatable(self).original:get_max_duration()
    end

    self.get_is_silent = function(self)
        return getmetatable(self).original:get_is_silent()
    end

    self.get_n_turns_elapsed = function(self)
        local metatable = getmetatable(self)
        return metatable.entity:get_status_n_turns_elapsed(metatable.original)
    end

    for which in range(
            "attack",
            "defense",
            "speed",
            "damage_dealt",
            "damage_received",
            "healing_performed",
            "healing_received"
    ) do
        self["get_" .. which .. "_offset"] = function(self)
            return getmetatable(self).original[which .. "_offset"]
        end

        self["get_" .. which .. "_factor"] = function(self)
            return getmetatable(self).original[which .. "_factor"]
        end
    end

    local valid_fields = {
        id = true,
        name = true,
        attack_offset = true,
        defense_offset = true,
        speed_offset = true,
        attack_factor = true,
        defense_factor = true,
        speed_factor = true,
        damage_dealt_factor = true,
        damage_received_factor = true,
        healing_performed_factor = true,
        healing_received_factor = true,
        damage_dealt_offset = true,
        damage_received_offset = true,
        healing_performed_offset = true,
        healing_received_offset = true,
    }
    metatable.__index = function(self, key)
        if valid_fields[key] == true then
            return self["get_" .. key](self)
        else
            rt.warning("In bt.StatusInterface:__index: trying to access property `" .. key .. "` of Status `" .. getmetatable(self).original:get_id() .. "`, but no such property exists")
            return nil
        end
    end

    metatable.__newindex = function(self, key, value)
        rt.warning("In bt.StatusInterface:__newindex: trying to set property `" .. key .. "` of Status `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
        return
    end
    return self
end