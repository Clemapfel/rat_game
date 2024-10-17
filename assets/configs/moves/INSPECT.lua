return {
    name = "Inspect",
    description = "Reveals additional information about target enemy",
    flavor_text = "",

    max_n_uses = POSITIVE_INFINITY,

    is_intrinsic = true,
    can_target_multiple = false,
    can_target_self = false,
    can_target_enemy = true,
    can_target_ally = false,

    sprite_id = "moves",
    sprite_index = "INSPECT",

    effect = function(self, user_targets)
        -- TODO
    end
}