return {
    name = "Test Equipment",

    sprite_id = "orbs",
    sprite_index = 1,

    hp_base_offset = 15,
    attack_base_offset = -100,
    defense_base_offset = 1,
    speed_base_offset = 69,

    attack_base_factor = 2,
    defense_base_factor = 0.9,
    speed_base_factor = 1.1,

    effect = function(self, holder)
        meta.assert_equip_interface(self)
        meta.assert_entity_interface(holder)
        println("[DBG] In " .. self:get_id() .. ".effect: effect applied to `" .. holder:get_id() .. "`")
    end
}