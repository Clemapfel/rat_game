return {
    name = "Defend",
    description = "Blocks all damage for one turn, fails if used repeatedly",

    sprite_id = "orbs",
    sprite_index = "PROTECT",

    animation_id = "",

    can_target_multiple = false,
    can_target_self = true,
    can_target_enemy = false,
    can_target_ally = false,

    priority = 0,
    max_n_uses = POSITIVE_INFINITY,
    is_intrinsic = true,

    effect = function(self, user, targets)
        assert(false)
    end
}