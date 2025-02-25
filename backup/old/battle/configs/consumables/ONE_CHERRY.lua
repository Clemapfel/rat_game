return {
    name = "HP Restoring Berry",
    description = "Restores 25% HP once if holders HP falls below 50%",

    max_n_uses = 1,
    restore_uses_after_battle = false,

    sprite_id = "menu_icons",
    sprite_index = 6,

    on_hp_lost = function(self, holder, damage_taker, value)
        -- TODO: if below 50%, restore 25%
    end,
}