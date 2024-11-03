return {
    name = "Debug Equip",

    description = "Inflicts $DEBUG_STATUS$ on wearer at start of battle",
    flavor_text = "Clothing yourself in debug does not protect yourself from the elements",

    sprite_id = "equips",
    sprite_index = "DEBUG_EQUIP",

    hp_base_offset = 0,
    attack_base_offset = 0,
    defense_base_offset = 0,
    speed_base_offset = 0,

    hp_base_factor = 1,
    attack_base_factor = 1,
    defense_base_factor = 1,
    speed_base_factor = 1,

    effect = function(self, entity)
        message("test")
    end
}