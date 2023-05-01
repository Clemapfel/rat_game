--- @class IgnitionEffect
rt.IgnitionEffect = meta.new_type("IgnitionEffect", {

    --- @brief (Entity self, Entity target, ...) -> string
    --- @param self Entity
    --- @param target Entity
    apply = meta.Function(),
})

--- @param f Function  (Entity, Entity, (any)) ->
--- @param message Function (Entity) -> string
meta.set_constructor(rt.IgnitionEffect, function(type, f)

    local out = meta.new(rt.IgnitionEffect)

    out.__meta.__call = function(instance, self, other, data)
        instance.apply(self, other, data)
    end

    if f == nil then
        return out
    end

    out.apply = function(self, other, data)
        meta.assert_type(rt.Entity, self)

        if other ~= nil then
            meta.assert_type(rt.Entity, other)
        end

        return f(self, other, data)
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

    --- @brief (Entity self, ContinuousEffect this) - nil
    on_status_gained = rt.IgnitionEffect(),

    --- @brief (Entity self, ContinuousEffect this) -> nil
    on_status_lost = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Number damage) -> nil
    on_damage_taken = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other) -> nil
    before_damage_taken = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Number damage) -> nil
    on_damage_dealt = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other) -> nil
    before_damage_dealt = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Move move) -> nil
    on_move_used = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Move move) -> nil
    before_move_used = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Item item) -> nil
    on_item_used = rt.IgnitionEffect(),

    --- @brief (Entity self, Entity other, Item item) -> nil
    before_item_used = rt.IgnitionEffect(),

    --- @brief (Entity self) -> nil
    on_turn_start = rt.IgnitionEffect(),

    --- @brief (Entity self) -> nil
    on_turn_end = rt.IgnitionEffect(),
})

rt.ContinuousEffect.__meta.__eq = function(self, other)
    return self.id == other.id
end

meta.set_constructor(rt.ContinuousEffect, function(self, args)

    local out = meta.new(rt.ContinuousEffect, args)
    if args == nil then
        return out
    end

    out.on_status_gained = rt.IgnitionEffect(args.on_status_gained)
    out.on_status_lost = rt.IgnitionEffect(args.on_status_lost)
    out.on_damage_taken = rt.IgnitionEffect(args.on_damage_taken)
    out.before_damage_taken = rt.IgnitionEffect(args.before_damage_taken)
    out.on_damage_dealt = rt.IgnitionEffect(args.on_damage_dealt)
    out.before_damage_dealt = rt.IgnitionEffect(args.before_damage_dealt)
    out.on_move_used = rt.IgnitionEffect(args.on_move_used)
    out.before_move_used = rt.IgnitionEffect(args.before_move_used)
    out.on_item_used = rt.IgnitionEffect(args.on_item_used)
    out.before_item_used = rt.IgnitionEffect(args.before_item_used)
    out.on_turn_start = rt.IgnitionEffect(args.on_turn_start)
    out.on_turn_end = rt.IgnitionEffect(args.on_turn_end)

    return out
end)

--- @brief add continuous effect
--- @param id String
--- @param arguments Table
--- @return ContinuousEffect
function rt.new_effect(id, args)
    args.id = id
    if args.name == nil then
        args.name = id
    end
    return rt.ContinuousEffect(args)
end

--- @brief add to entity
--- @param entity Entity
--- @param effect ContinuousEffect
function rt.add_effect(entity, effect)

    meta.assert_type(rt.Entity, entity, "add_effect", 1)
    meta.assert_type(rt.ContinuousEffect, effect, "add_effect", 2)

    if entity.effects:insert(effect) then
        -- @todo log
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
            -- @todo log
            return
        end
    end
end




