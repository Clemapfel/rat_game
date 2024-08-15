rt.settings.battle.config_atlas = {
    move_path = "assets/configs/moves",
    status_path = "assets/configs/status",
    equip_path = "assets/config/equip",
    consumable_path = "assets/config/consumable"
}

--- @class bt.ConfigAtlas
bt.ConfigAtlas = meta.new_type("BattleConfigAtlas", function()

end)

bt.ConfigAtlas = bt.ConfigAtlas(rt.settings)-- singleton instance