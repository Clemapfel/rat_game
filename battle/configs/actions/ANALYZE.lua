return {
    name = "Analyze",
    effect_text = "Reveal information",
    verbose_effect_text = "First use: shows targets HP and SPD; Second use: also show targets PP. Lasts until the end of the battle.",
    flavor_text = "Knowledge is Power",

    type = "INTRINSIC",
    max_n_uses = POSITIVE_INFINITY,

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = false,
    can_target_ally = false,
    can_target_enemy = true,

    thumbnail_id = "analyze",
    animation_id = "analyze"
}