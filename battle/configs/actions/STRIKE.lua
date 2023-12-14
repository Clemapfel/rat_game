return {
    name = "Strike",
    effect_text = "Deals damage to single target",
    verbose_effect_text = "If attacking an enemy, deals [1 * user.attack] damage. If attacking an ally, this damage is reduce by 75%",
    flavor_text = "Some people just need a wake-up slap",

    type = "INTRINSIC",
    max_n_uses = POSITIVE_INFINITY,

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = false,
    can_target_ally = true,
    can_target_enemy = true,

    thumbnail_id = "strike",
    animation_id = "strike"
}