--- @class bt.ConsumableInterface
bt.ConsumableInterface = {
    --- @brief
    get_id = function(self)
        meta.assert_consumable_interface(self)
        return getmetatable(self).original:get_id()
    end,

    --- @brief
    get_name = function(self)
        meta.assert_consumable_interface(self)
        return getmetatable(self).original:get_name()
    end,

    --- @brief
    get_formatted_name = function(self)
        meta.assert_consumable_interface(self)
        return getmetatable(self).scene:format_name(getmetatable(self).original)
    end,

    --- @brief
    get_max_duration = function(self)
        meta.assert_consumable_interface(self)
        return getmetatable(self).original:get_max_duration()
    end,

    --- @brief
    get_is_silent = function(self)
        meta.assert_consumable_interface(self)
        return getmetatable(self).original:get_is_silent()
    end,

    --- @brief
    get_n_uses_left = function(self)
        meta.assert_consumable_interface(self)
        local metatable = getmetatable(self)
        return metatable.entity:get_consumable_n_uses_left(metatable.original)
    end
}

--- @brief ctor
setmetatable(bt.ConsumableInterface, {
    __call = function(_, scene, entity, consumable)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_isa(consumable, bt.Consumable)

        local self, metatable = {}, {}
        setmetatable(self, metatable)

        metatable.type = "bt.ConsumableInterface"
        metatable.scene = scene
        metatable.entity = entity
        metatable.original = consumable

        for key, value in pairs(bt.ConsumableInterface) do
            self[key] = value
        end

        local valid_fields = {
            id = true,
            name = true,
            max_n_uses = true,
            n_uses_left = true,
            is_silent = true
        }

        metatable.__index = function(self, key)
            if valid_fields[key] == true then
                return self["get_" .. key](self)
            else
                rt.warning("In bt.ConsumableInterface:__index: trying to access property `" .. key .. "` of Consumable `" .. getmetatable(self).original:get_id() .. "`, but no such property exists")
                return nil
            end
        end

        metatable.__newindex = function(self, key, value)
            rt.warning("In bt.ConsumableInterface:__newindex: trying to set property `" .. key .. "` of Consumable `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
            return
        end
        return self
    end
})