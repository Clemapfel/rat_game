return {
    name = "Test Move",
    effect_text = "This is a move used for testing",
    verbose_effect_text = "moves have a set number of uses that can be replenished",
    flavor_text = "Truly useless",

    type = "MOVE",
    max_n_uses = 14,

    targeting_mode = bt.TargetingMode.SINGLE,
    can_target_self = true,
    can_target_ally = true,
    can_target_enemy = true,

    sprite_id = "default",
    animation_id = "default"
}