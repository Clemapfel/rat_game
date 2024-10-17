return {
    name = "Wish",
    description = "Make a wish at the start of this turn, will come true next turn and restor 50% of users hp",

    sprite_id = "orbs",
    sprite_index = "WISH",

    animation_id = "",

    can_target_multiple = false,
    can_target_self = true,
    can_target_enemy = false,
    can_target_ally = true,

    priority = 2,
    max_n_uses = 13,

    effect = function(self, user, targets)
        assert(false)
    end
}