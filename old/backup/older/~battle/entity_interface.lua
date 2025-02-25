--- @class bt.StatusInterface
function bt.StatusInterface(scene, entity, status)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.BattleEntity)
    meta.assert_isa(status, bt.Status)

    local self, metatable = {}, {}
    setmetatable(self, metatable)

    metatable.type = "bt.EntityInterface"
    metatable.scene = scene
    metatable.entity = entity
    metatable.original = status

    self.get_id = function(self)
        return getmetatable(self).original:get_id()
    end

    self.get_name = function(self)
        return getmetatable(self).original:get_name()
    end


    local valid_fields = {

    }
    metatable.__index = function(self, key)

    end

    metatable.__newindex = function(self, key, value)
        return
    end
    return self
end