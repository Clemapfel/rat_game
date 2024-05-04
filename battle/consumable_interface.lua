
--- @class bt.ConsumableInterface
function bt.ConsumableInterface(scene, entity, consumable)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(consumable, bt.Consumable)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.ConsumableInterface"
    metatable.scene = scene
    metatable.entity = entity
    metatable.original = consumable

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

    self.get_n_uses_left = function(self)
        local metatable = getmetatable(self)
        return metatable.entity:get_consumable_n_uses_left(metatable.original)
    end

    self.consume = function(self)
        local metatable = getmetatable(self)
        metatable.scene:consume(metatable.entity, metatable.original)
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