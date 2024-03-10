--- @class bt.EntityProxy
--- @field hp Number
--- @field
bt.EntityProxy = function(entity)
    local self = {}
    local metatable = {}
    setmetatable(self, metatable)
    metatable.entity = entity

    -- add getter / setters as direct fields
    for forward in range(
        "get_hp",
        "set_hp"
    ) do
        self[forward] = load(string.format([[
            return function (self, ...)
                return getmetatable(self).entity:%s(...)
            end
        ]], forward))()
    end

    -- for others, manually map field it to getter/setter behavior
    metatable.__index = function(self, key)
        local entity = getmetatable(self).entity
        if key == "hp" then
            return entity:get_hp()
        else
            rt.error("In bt:EntityProxy: attempting to access field `" .. key .. "`, which does not exist or was declared private")
        end
    end

    metatable.__newindex = function(self, key, new_value)
        local entity = getmetatable(self).entity
        if key == "hp" then
            entity:set_hp(new_value)
        else
            rt.error("In bt:EntityProxy: attempting to mutate field `" .. key .. "`, which does not exist or cannot be mutated directly")
        end
    end

    return self
end