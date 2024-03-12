--- @class bt.EntityProxy
--- @field hp Number
--- @field
bt.EntityProxy = meta.new_type("EntityProxy", function (entity)
    local self = {}
    local metatable = {}
    setmetatable(self, metatable)
    metatable.entity = entity

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
        if true then
            rt.error("In bt:EntityProxy: attempting to mutate field `" .. key .. "`, which does not exist or cannot be mutated directly")
        end
    end

    return self
end)

--- @brief
function bt.EntityProxy:raise_hp(value)
    if value < 0 then self:lower_hp(math.abs(value)) end
    if value == 0 then return end

    local self = getmetatable(self).entity
    value = math.min(value, self.hp_base - self.hp_current)
    for _, status in pairs(self.status) do
        value = value * status.heal_factor
    end

    if self.is_dead then
        self.scene:play_animation(self, bt.Animation.ALREADY_DEAD(self))
    elseif self.is_knocked_out then
        self.hp_current = value
        self.is_knocked_out = false
        self.scene:play_animation(self, bt.Animation.HELP_UP(self))
        self.scene:play_animation(self, bt.Animation.HP_GAINED(self, value))
    else
        value = clamp(value, self.hp_base - self.hp_current)
        self.hp_current = self.hp_current + value
        self.scene:play_animation(self, bt.Animation.HP_GAINED(self, value))
    end
end

--- @brief
function bt.EntityProxy:lower_hp(value)
    if value < 0 then self:raise_hp(math.abs(value)) end
    if value == 0 then return end

    local self = getmetatable(self).entity
    value = math.min(value, self.hp_current)
    for _, status in pairs(self.status) do
        value = value * status.damage_factor
    end

    if self.hp_current - value <= 0 then
        self.hp_current = 0
        if self.is_dead then
            self.scene:play_animation(self, bt.Animation.ALREADY_DEAD(self))
        elseif self.is_knocked_out == true then
            self.is_dead = true
            self.scene:play_animation(self, bt.Animation.HP_LOST(self, value))
            self.scene:play_animation(self, bt.Animation.KILLED(self))
        else
            self.is_knocked_out = true
            self.scene:play_animation(self, bt.Animation.HP_LOST(self, value))
            self.scene:play_animation(self, bt.Animation.KNOCKED_OUT(self))
        end
    else
        self.hp_current = self.hp_current - value
        self.scene:play_animation(self, bt.Animatino.HP_LOST(self, value))
    end
end