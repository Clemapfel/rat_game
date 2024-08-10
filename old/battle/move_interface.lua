--- @class bt.MoveInterface
bt.MoveInterface = {
    --- @brief
    get_id = function(self)
        meta.assert_move_interface(self)
        return getmetatable(self).original:get_id()
    end,

    --- @brief
    get_name = function(self)
        meta.assert_move_interface(self)
        return getmetatable(self).original:get_name()
    end,

    --- @brief
    get_formatted_name = function(self)
        meta.assert_move_interface(self)
        return getmetatable(self).scene:format_name(getmetatable(self).original)
    end,

    --- @brief
    get_max_n_uses = function(self)
        meta.assert_move_interface(self)
        return getmetatable(self).original:get_max_n_uses()
    end,

    --- @brief
    get_can_target_multiple = function(self)
        meta.assert_move_interface(self)
        return getmetatable(self).original:get_can_target_multiple()
    end,

    --- @brief
    get_can_target_self = function(self)
        meta.assert_move_interface(self)
        return getmetatable(self).original:get_can_target_self()
    end,

    --- @brief
    get_can_target_ally = function(self)
        meta.assert_move_interface(self)
        return getmetatable(self).original:get_can_target_ally()
    end,

    --- @brief
    get_can_target_enemy = function(self)
        meta.assert_move_interface(self)
        return getmetatable(self).original:get_can_target_enemy()
    end,

    --- @brief
    get_priority = function(self)
        meta.assert_move_interface(self)
        return getmetatable(self).original:get_priority()
    end
}

--- @class bt.MoveInterface
setmetatable(bt.MoveInterface, {
    __call = function(_, scene, move)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(move, bt.Move)

        local self, metatable = {}, {}
        setmetatable(self, metatable)

        metatable.type = "bt.MoveInterface"
        metatable.scene = scene
        metatable.original = move

        for key, value in pairs(bt.MoveInterface) do
            self[key] = value
        end

        local valid_fields = {
            id = true,
            name = true,
            max_n_uses = true,
            can_target_multiple = true,
            can_target_self = true,
            can_target_ally = true,
            priority = true
        }

        metatable.__index = function(self, key)
            if valid_fields[key] == true then
                return self["get_" .. key](self)
            else
                rt.warning("In bt.MoveInterface:__index: trying to access property `" .. key .. "` of Move `" .. getmetatable(self).original:get_id() .. "`, but no such property exists")
                return nil
            end
        end

        metatable.__newindex = function(self, key, value)
            rt.warning("In bt.MoveInterface:__newindex: trying to set property `" .. key .. "` of Move `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
            return nil
        end
        return self
    end
})