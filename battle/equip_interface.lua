--- @class bt.EquipInterface
function bt.EquipInterface(scene, equip)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(equip, bt.Equip)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.EquipInterface"
    metatable.scene = scene
    metatable.original = equip

    self.get_id = function(self)
        return getmetatable(self).original:get_id()
    end

    self.get_name = function(self)
        return getmetatable(self).original:get_name()
    end

    self.get_hp_base_offset = function(self)
        return getmetatable(self).original:get_hp_base_offset()
    end

    self.get_attack_base_offset = function(self)
        return getmetatable(self).original:get_attack_base_offset()
    end

    self.get_defense_base_offset = function(self)
        return getmetatable(self).original:get_defense_base_offset()
    end

    self.get_speed_base_offset = function(self)
        return getmetatable(self).original:get_speed_base_offset()
    end

    self.get_hp_base_factor = function(self)
        return getmetatable(self).original:get_hp_base_factor()
    end

    self.get_attack_base_factor = function(self)
        return getmetatable(self).original:get_attack_base_factor()
    end

    self.get_defense_base_factor = function(self)
        return getmetatable(self).original:get_defense_base_factor()
    end

    self.get_speed_base_factor = function(self)
        return getmetatable(self).original:get_speed_base_factor()
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


