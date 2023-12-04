return {
    name = "Test Move",
    effect_text = "Deals damage to target",
    verbose_effect_text = "Deal damage to single target, this effect text is verbose and has a lot more characters",

    is_consumable = false,
    max_n_uses = 14,

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = true,
    can_target_ally = true,
    can_target_enemy = true,

    thumbnail_id = "default",
    animation_id = "default"
}