return {
    name = "Stab",
    description = "Deals small amount of damage, then inflicts $BLEEDING$",
    flavor_text = "",

    max_n_uses = POSITIVE_INFINITY,

    is_intrinsic = false,

    can_target_multiple = false,
    can_target_self = false,
    can_target_enemy = true,
    can_target_ally = true,

    sprite_id = "moves",
    sprite_index = "STAB",

    effect = function(self, user, target)
        deal_damage(target, 0.5 * get_attack(user))
        if has_status(user, STATUS_BLEEDING) then
            local current = get_value(user, N_BLEEDING_STACKS)
            set_value(user, N_BLEEDING_STACKS, current + 1)
        end
    end
}