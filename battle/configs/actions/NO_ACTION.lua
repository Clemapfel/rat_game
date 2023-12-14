return {
    name = "Wait",
    effect_text = "Act last, but do nothing",
    verbose_effect_text = "Instead of taking an action, user will have negative priority this turn",
    flavor_text = "",

    type = "INTRINSIC",
    max_n_uses = POSITIVE_INFINITY,

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = true,
    can_target_ally = false,
    can_target_enemy = false,

    sprite_id = "no_action",
    animation_id = "no_action"
}