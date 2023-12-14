return {
    name = "Test Consumable",
    effect_text = "Consumable Item Action used for testing",
    verbose_effect_text = "consumables have a fixed number of uses, cannot be replenished",
    flavor_text = "intrinsic action",

    type = "INTRINSIC",

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = true,
    can_target_ally = true,
    can_target_enemy = true,

    sprite_id = "default",
    animation_id = "default"
}