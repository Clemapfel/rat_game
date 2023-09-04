--- @class StatusStatModifier
rt.StatusStatModifier = meta.new_type("StatusStatModifier", function(factor, offset)

    if meta.is_nil(factor) then
        factor = 1
    else
        meta.assert_number(factor)
    end

    if meta.is_nil(offset) then
        offset = 0
    else
        meta.assert_number(offset)
    end

    return meta.new(rt.StatusStatModifier, {
        factor = factor,
        offset = offset
    })
end)

--- @class Status
rt.StatusConfig = meta.new_type("StatusConfig", function(config)

    meta.assert_string(config.name)
    meta.assert_string(config.description)

    local out = meta.new(rt.Status, {
        name = "",
        description = "",

        duration = POSITIVE_INFINITY,

        attack_modifier = rt.StatusStatModifier(),
        defense_modifier = rt.StatusStatModifier(),
        speed_modifier = rt.StatusStatModifier(),

        on_status_gained = function(self, new_status)
            meta.assert_isa(self, rt.Entity)
            meta.assert(rt.STATUS[new_status] ~= nil)
            return nil
        end,
        on_status_lost = function(self, new_status)
            meta.assert_isa(self, rt.Entity)
            meta.assert(rt.STATUS[new_status] ~= nil)
            return nil
        end,
        on_turn_start = function(self)
            meta.assert_isa(self, rt.BattleEntity)
            return nil
        end,
        on_turn_end = function(self)
            meta.assert_isa(self, rt.BattleEntity)
            return nil
        end,
        on_damage_taken = function(self, value)
            meta.assert_isa(self, rt.BattleEntity)
            meta.assert_number(value)
            return 1 * value
        end,
        on_damage_dealt = function(self, value)
            meta.assert_isa(self, rt.BattleEntity)
            meta.assert_number(value)
            return 1 * value
        end
    })

    for key, value in pairs(config) do
        out[key] = value
    end
    meta.set_is_mutable(out, false)
    return out
end)

rt.STATUS = {
}

for id, config in pairs(rt.STATUS) do
    meta._install_property(config, "id", id)
end