return {
    name = "Explosion",
    description = "Deals 4x user attack to all entities in battle, including user",
    flavor_text = "",

    max_n_uses = POSITIVE_INFINITY,

    is_intrinsic = false,

    can_target_multiple = true,
    can_target_self = false,
    can_target_enemy = false,
    can_target_ally = false,

    sprite_id = "moves",
    sprite_index = "BOMB",

    effect = function(self, user_targets)
        -- TODO
    end
}