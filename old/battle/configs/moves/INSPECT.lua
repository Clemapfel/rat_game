return {
    name = "Inspect",
    description = "Reveal information about Enemey",

    sprite_id = "orbs",
    sprite_index = "INSPECT",

    animation_id = "",

    can_target_multiple = false,
    can_target_self = false,
    can_target_enemy = true,
    can_target_ally = false,

    priority = 0,
    max_n_uses = POSITIVE_INFINITY,

    effect = function(self, user, targets)
        assert(false)
    end
}