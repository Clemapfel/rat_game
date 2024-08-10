--- @class bt.GlobalStatusInterface
bt.GlobalStatusInterface = {
    --- @brief
    get_id = function(self)
        meta.assert_global_status_interface(self)
        return getmetatable(self).original:get_id()
    end,

    --- @brief
    get_name = function(self)
        meta.assert_global_status_interface(self)
        return getmetatable(self).original:get_name()
    end,

    --- @brief
    get_formatted_name = function(self)
        meta.assert_global_status_interface(self)
        return getmetatable(self).scene:format_name(getmetatable(self).original)
    end,

    --- @brief
    get_is_silent = function(self)
        meta.assert_global_status_interface(self)
        return getmetatable(self).original:get_is_silent()
    end,

    --- @brief
    get_max_duration = function(self)
        meta.assert_global_status_interface(self)
        return getmetatable(self).original:get_max_duration()
    end,

    --- @brief
    get_n_turns_elapsed = function(self)
        meta.assert_global_status_interface(self)
        local metatable = getmetatable(self)
        return metatable.scene:get_state():get_global_status_n_turns_elapsed(metatable.original)
    end
}

--- @brief ctor
setmetatable(bt.GlobalStatusInterface, {
    __call = function(_, scene, status)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(status, bt.GlobalStatus)

        local self, metatable = {}, {}
        setmetatable(self, metatable)

        metatable.type = "bt.GlobalStatusInterface"
        metatable.scene = scene
        metatable.original = status

        for key, value in pairs(bt.GlobalStatusInterface) do
            self[key] = value
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
})
