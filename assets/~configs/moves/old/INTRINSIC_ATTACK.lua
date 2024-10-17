return {
    name = "Attack",
    description = "Deals 1x user.attack damage to target, no additional effect",

    sprite_id = "orbs",
    sprite_index = "STRUGGLE",

    animation_id = "",

    is_intrinsic = true,
    can_target_multiple = false,
    can_target_self = false,
    can_target_enemy = true,
    can_target_ally = true,

    priority = 0,
    max_n_uses = POSITIVE_INFINITY,

    effect = function(self, user, targets)
        assert(false)
    end
}