return {
    name = "Help Up",
    description = "Restores knocked out ally at 25% HP",
    flavor_text = "",

    max_n_uses = POSITIVE_INFINITY,

    is_intrinsic = true,

    can_target_multiple = false,
    can_target_self = true,
    can_target_enemy = false,
    can_target_ally = false,

    sprite_id = "moves",
    sprite_index = "HELP_UP",

    effect = function(self, user_targets)
        -- TODO
    end
}