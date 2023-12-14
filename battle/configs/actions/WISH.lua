return {
    name = "Wish",
    effect_text = "Wish for healing",
    verbose_effect_text = "Makes a wish targeting self or ally. In 1 - 3 turns, the target will be healed by 50% of the users base HP",
    flavor_text = "It's the law of attraction",

    type = "INTRINSIC",
    max_n_uses = POSITIVE_INFINITY,

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = true,
    can_target_ally = true,
    can_target_enemy = false,

    sprite_id = "wish",
    animation_id = "wish"
}