return {
    name = "Test BattleScene",
    description = "Runs system diagnostics, do not use this",
    flavor_text = "Seriously, don't use it",

    max_n_uses = 1,

    is_intrinsic = false,
    can_target_multiple = false,
    can_target_self = true,
    can_target_enemy = true,
    can_target_ally = true,

    sprite_id = "moves",
    sprite_index = "TEST",

    effect = function(self, user, targets)
        println("test")
    end
}