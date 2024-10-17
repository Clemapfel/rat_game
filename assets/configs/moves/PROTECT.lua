return {
    name = "Protect",
    description = "Protects user from all damage, fails if used twice in a row",
    flavor_text = "Safe for now.",

    max_n_uses = POSITIVE_INFINITY,

    is_intrinsic = true,
    can_target_multiple = false,
    can_target_self = true,
    can_target_enemy = false,
    can_target_ally = false,

    sprite_id = "moves",
    sprite_index = "PROTECT",

    effect = function(self, user_targets)
        -- TODO
    end
}