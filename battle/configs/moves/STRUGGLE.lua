return {
    name = "Struggle",
    description = "Deals 1x user.attack damage to target",

    sprite_id = "orbs",
    sprite_index = "STRUGGLE",

    animation_id = "",

    can_target_multiple = false,
    can_target_self = false,
    can_target_enemy = true,
    can_target_ally = true,

    priority = 0,
    max_n_uses = POSITIVE_INFINITY,
    is_intrinsic = true,

    effect = function(self, user, targets)
        assert(false)
    end
}