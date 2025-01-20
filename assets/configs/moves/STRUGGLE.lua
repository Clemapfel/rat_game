return {
    name = "Struggle",
    description = "Damages enemy for 0.5x user.attack, deals 25% of damage dealt to user",
    flavor_text = "A last resort",

    max_n_uses = POSITIVE_INFINITY,

    is_intrinsic = true,
    can_target_multiple = false,
    can_target_self = false,
    can_target_enemy = true,
    can_target_ally = true,

    sprite_id = "moves",
    sprite_index = "STRUGGLE",


    effect = function(self, user, targets)
        reduce_hp(targets, 0.5 * get_attack(user))
    end
}