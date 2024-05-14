--- @class bt.EntityInterface
function bt.EntityInterface(scene, entity)
    meta.assert_isa(scene, bt.Scene)
    meta.assert_isa(entity, bt.Entity)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.EntityInterface"
    metatable.scene = scene
    metatable.original = entity

    self.get_id = function(self)
        return getmetatable(self).original:get_id()
    end

    self.get_name = function(self)
        return getmetatable(self).original:get_name()
    end

    self.get_is_enemy = function(self)
        return getmetatable(self).original:get_is_enemy()
    end

    local valid_fields = {
        id = true,
        name = true,
        is_enemy = true
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