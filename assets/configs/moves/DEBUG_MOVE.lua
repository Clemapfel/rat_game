return {
    name = "Debug Move",
    description = "Does nothing",
    flavor_text = "",

    max_n_uses = POSITIVE_INFINITY,

    is_intrinsic = false,

    can_target_multiple = false,
    can_target_self = true,
    can_target_enemy = true,
    can_target_ally = true,

    sprite_id = "moves",
    sprite_index = "DEBUG_MOVE",

    effect = function(self, user_targets)
        -- TODO
    end
}