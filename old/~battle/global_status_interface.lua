
--- @class bt.GlobalStatusInterface
function bt.GlobalStatusInterface(scene, status)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.GlobalStatus)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.GlobalStatusInterface"
    metatable.scene = scene
    metatable.original = status

    self.get_id = function(self)
        return getmetatable(self).original:get_id()
    end

    self.get_name = function(self)
        return getmetatable(self).original:get_name()
    end

    self.get_is_silent = function(self)
        return getmetatable(self).original:get_is_silent()
    end

    self.get_max_duration = function(self)
        return getmetatable(self).original:get_max_duration()
    end

    self.get_n_turns_elapsed = function(self)
        local metatable = getmetatable(self)
        return metatable.scene:get_state():get_global_status_n_turns_elapsed(metatable.original)
    end

    local valid_fields = {
        id = true,
        name = true,
        max_duration = true,
        n_turns_elapsed = true,
        is_silent = true
    }

    metatable.__index = function(self, key)
        if valid_fields[key] == true then
            return self["get_" .. key](self)
        else
            rt.warning("In bt.GlobalStatusInterface:__index: trying to access property `" .. key .. "` of GlobalStatus `" .. getmetatable(self).original:get_id() .. "`, but no such property exists")
            return nil
        end
    end

    metatable.__newindex = function(self, key, value)
        rt.warning("In bt.GlobalStatusInterface:__newindex: trying to set property `" .. key .. "` of GlobalStatus `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
        return nil
    end

    return self
end
