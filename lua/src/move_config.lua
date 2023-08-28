--- @class Priority
rt.Priority = meta.new_enum({
    MIN = NEGATIVE_INFINITY,
    NEGATIVE = -1,
    NEUTRAL = 0,
    POSITIVE = 1,
    MAX = POSITIVE_INFINITY
})

--- @class MoveConfig
rt.MoveConfig = meta.new_type("MoveConfig", function(config)

    meta.assert_string(config.name)
    meta.assert_string(config.description)

    local out = meta.new(rt.MoveConfig, {
        name = "",
        description = "",

        pp_base = POSITIVE_INFINITY,

        can_target_self = false,
        can_target_enemy = true,
        can_target_ally = true,

        apply = function(self, target)
            meta.assert_type(self, rt.BattleEntity)
            meta.assert_type(self, rt.BattleEntity)
        end
    })

    for key, value in pairs(config) do
        out[key] = value
    end

    meta.set_is_mutable(out, false)
    return out
end)

rt.MOVES = {
    BASE_ATTACK = rt.MoveConfig({
        name = "Attack",
        description = "Simple attack, deals 1x$ATTACK to target enemy",

        can_target_self = false,
        can_target_enemy = true,
        can_target_ally = false,

        apply = function(self, target)
            target:reduce_hp(self.attack)
        end
    }),

    BASE_PROTECT = rt.MoveConfig({
        name = "Protect",
        description = "Prevents any damage done to user this turn",

        can_target_self = true,
        can_target_enemy = false,
        can_target_ally = false,

        apply = function(self, target)
            self:add_status(rt.STATUS.BASE_PROTECT)
        end
    })
}

for id, config in pairs(rt.MOVES) do
    meta._install_property(config, "id", id)
end