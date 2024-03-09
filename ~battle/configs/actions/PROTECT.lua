return {
    name = "Protect",
    effect_text = "Protects self, cannot be used 2 turns in a row",
    verbose_effect_text = "Reduces all damage dealt to the user to 0, any newly inflicted status ailments will be ignored. If this move is used in 2 consequetive turns, it will fail.",
    flavor_text = "Defense is the best Defense",

    type = "INTRINSIC",
    max_n_uses = POSITIVE_INFINITY,

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = true,
    can_target_ally = false,
    can_target_enemy = false,

    sprite_id = "protect",
    animation_id = "protect"
}