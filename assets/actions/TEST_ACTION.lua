return {
    name = "Test Move",
    effect_text = "Deals [1*user.attack] to target enemy",

    is_consumable = false,
    max_n_uses = 14,

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = true,
    can_target_ally = true,
    can_target_enemy = true,

    thumbnail_id = "default",
    animation_id = "default"
}