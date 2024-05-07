return {
    name = "Crashing Wave",
    description = "Deals damage to all enemies and allies, not self",

    sprite_id = "orbs",
    sprite_index = 8,

    animation_id = "",

    can_target_multiple = true,
    can_target_self = false,
    can_target_enemy = true,
    can_target_ally = true,

    priority = 0,
    max_n_uses = 3,

    effect = function(self, user, targets)
        assert(false)
    end
}