--- @class bt.EquipInterface
bt.EquipInterface = {
    --- @brief
    get_id = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_id()
    end,

    --- @brief
    get_name = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_name()
    end,

    --- @brief
    get_formatted_name = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).scene:format_name(getmetatable(self).original)
    end,

    --- @brief
    get_is_silent = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).is_silent
    end,

    --- @brief
    get_hp_base_offset = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_hp_base_offset()
    end,

    --- @brief
    get_attack_base_offset = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_attack_base_offset()
    end,

    --- @brief
    get_defense_base_offset = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_defense_base_offset()
    end,

    --- @brief
    get_speed_base_offset = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_speed_base_offset()
    end,

    --- @brief
    get_hp_base_factor = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_hp_base_factor()
    end,

    --- @brief
    get_attack_base_factor = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_attack_base_factor()
    end,

    --- @brief
    get_defense_base_factor = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_defense_base_factor()
    end,

    --- @brief
    get_speed_base_factor = function(self)
        meta.assert_equip_interface(self)
        return getmetatable(self).original:get_speed_base_factor()
    end
}

setmetatable(bt.EquipInterface, {
    __call = function(_, scene, equip)
        meta.assert_isa(scene, bt.Scene)
        meta.assert_isa(equip, bt.EquipConfig)

        local self, metatable = {}, {}
        setmetatable(self, metatable)

        metatable.type = "bt.EquipInterface"
        metatable.scene = scene
        metatable.original = equip

        for key, value in pairs(bt.EquipInterface) do
            self[key] = value
        end

        local valid_fields = {
            id = true,
            name = true,
            is_silent = true,
            hp_base_offset = true,
            attack_base_offset = true,
            defense_base_offset = true,
            speed_base_offset = true,

            hp_base_factor = true,
            attack_base_factor = true,
            defense_base_factor = true,
            speed_base_factor = true,
        }

        metatable.__index = function(self, key)
            if valid_fields[key] == true then
                return self["get_" .. key](self)
            else
                rt.warning("In bt.EquipInterface:__index: trying to access property `" .. key .. "` of Equip `" .. getmetatable(self).original:get_id() .. "`, but no such property exists")
                return nil
            end
        end

        metatable.__newindex = function(self, key, value)
            rt.warning("In bt.EquipInterface:__newindex: trying to set property `" .. key .. "` of Equip `" .. getmetatable(self).original:get_id() .. "` to `" .. serialize(value) .. "`, but interface is immutable")
            return nil
        end
        return self
    end
})


