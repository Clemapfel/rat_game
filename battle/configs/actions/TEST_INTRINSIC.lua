return {
    name = "Test Intrinsic",
    effect_text = "Intrinsic action used for testing",
    verbose_effect_text = "intrinsic actions used instead of moves because they are always equipped and can be used infinitely",
    flavor_text = "intrinsic action",

    type = "INTRINSIC",

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = true,
    can_target_ally = true,
    can_target_enemy = true,

    sprite_id = "default",
    animation_id = "default"
}