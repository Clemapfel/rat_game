--- @class IgnitionEffect
rt.IgnitionEffect = meta.new_type("IgnitionEffect", {

    --- @brief (Entity self, Entity target, ...) -> string
    --- @param self Entity
    --- @param target Entity
    apply = meta.Function(),
})

--- @param f Function  (Entity, Entity, (any)) ->
--- @param message Function (Entity) -> string
meta.set_constructor(rt.IgnitionEffect, function(type, f, message)

    local out = meta.new(rt.IgnitionEffect)
    out.apply = function(self, other, data)
        meta.assert_type(rt.Entity, self)

        if other ~= nil then
            meta.assert_type(rt.Entity, other)
        end

        return f(self, other, data)
    end

    out.on_apply_message = message

    out.__meta.__call = function(instance, self, other, data)
        instance.apply(self, other, data)
    end

    return out
end)

--- @class ContinuousEffect
rt.ContinuousEffect = meta.new_type("ContinuousEffect", {

    id = "",
    name = "",
    description = "TODO",

    duration = POSITIVE_INFINITY,

    is_stun = false,

    hp_factor = meta.Number(1),
    hp_offset = meta.Number(0),

    ap_factor = meta.Number(1),
    ap_offset = meta.Number(0),

    attack_factor = meta.Number(1),
    attack_offset = meta.Number(0),

    defense_factor = meta.Number(1),
    defense_offset = meta.Number(0),

    speed_factor = meta.Number(1),
    speed_offset = meta.Number(0),

    --- @param entity Entity self
    --- @param entity Entity person that transmitted status on self, or nil if it was a global
    --- @param status ContinuousEffect
    on_status_gained = rt.IgnitionEffect(),

    --- @brief (Entity self, Continuonous this)
    --- @param self Entity entity loosing the status
    --- @param entity Entity entity that originally inflicted the status
    on_status_lost = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Number damage) -> nil
    after_damage_taken = rt.IgnitionEffect(),
    before_damage_taken = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Number damage) -> nil
    after_damage_dealt = rt.IgnitionEffect(),
    before_damage_dealt = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Move move) -> nil
    before_move_used = rt.IgnitionEffect(),
    after_move_used = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Item item) -> nil
    before_item_used = rt.IgnitionEffect(),
    after_item_used = rt.IgnitionEffect(),

    --- @brief (Entity self) -> nil
    on_turn_start = rt.IgnitionEffect(),
    on_turn_end = rt.IgnitionEffect(),
})

rt.ContinuousEffect.__meta.__eq = function(self, other)
    return self.id == other.id
end

--- @brief add continuous effect
--- @param id string
--- @param arguments table
--- @return ContinuousEffect
rt._ContinuousEffects = {}
function rt.new_effect(id, args)
    args[id] = id
    local out = meta.new(rt.ContinuousEffect, args)
    rt._ContinuousEffects[id] = out
    return out
end

--- @brief access global database
--- @param id string
--- @return ContinuousEffect or nil
function rt.get_effect(id)
    return rt._ContinuousEffects[id]
end

--- @brief add to entity
--- @param entity Entity
--- @param effect ContinuousEffect
function rt.add_effect(entity, effect)

    meta.assert_type(rt.Entity, entity, "add_effect", 1)
    meta.assert_type(rt.ContinuousEffect, effect, "add_effect", 2)

    if entity.effects:insert(effect) then
        log.message(effect.status_gained_message(entity))
    end
end

--- @brief check if effect is present
--- @param entity Entity
--- @param effect ContinuousEffect
function rt.has_effect(entity, effect)

    meta.assert_type(rt.Entity, entity, "has_effect", 1)
    meta.assert_type(rt.ContinuousEffect, effect, "has_effect", 2)

    for value in pairs(entity.effects) do
        if value.id == effect.id then
            return true
        end
    end
    return false
end

--- @brief remove effect
--- @param entity Entity
--- @param effect ContinuousEffect
function rt.remove_effect(entity, effect)

    meta.assert_type(rt.Entity, entity, "has_effect", 1)
    meta.assert_type(rt.ContinuousEffect, effect, "has_effect", 2)

    for value in pairs(entity.effects) do
        if value.id == effect.id then
            entity.effects:erase(effect)
            log.message(effect.status_lost_message(entity))
            return
        end
    end
end




