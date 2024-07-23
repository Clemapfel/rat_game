return {
    name = "Test Equipment",

    sprite_id = "orbs",
    sprite_index = 1,

    description = "Equipment used for debugging. Applies $DEBUG_STATUS at the start of the battle.",
    flavor_text = "If you read this, it means you have broken beyond the limits of this game, you are now god",

    hp_base_offset = 15,
    attack_base_offset = -100,
    defense_base_offset = 1,
    speed_base_offset = 69,

    hp_base_factor = 1.1,
    attack_base_factor = 2,
    defense_base_factor = 0.9,
    speed_base_factor = 1.1,

    effect = function(self, holder)
        meta.assert_equip_interface(self)
        meta.assert_entity_interface(holder)
        self:add_status("DEBUG_STATUS")
    end
}