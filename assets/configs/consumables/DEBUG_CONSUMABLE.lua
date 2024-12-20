return {
    name = "Debug Consumable",

    description = "Prints debug message for every consumable trigger",
    flavor_text = "Taste the Debug",

    sprite_id = "consumables",
    sprite_index = "DEBUG_CONSUMABLE",

    max_n_uses = 1,
    restore_uses_after_battle = true,

    on_gained = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. " on_gained")
    end,

    on_lost = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. " on_lost")
    end,

    on_turn_start = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. " on_turn_start")
    end,

    on_turn_end = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. "on_turn_end")
    end,

    on_battle_start = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. " on_battle_start")
    end,

    on_battle_end = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. " on_battle_end")
    end,

    on_hp_gained = function(self, holder, value)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_number(value)
        println(get_id(holder) .. " " .. get_id(self) .. " on_hp_gained")
    end,

    on_hp_lost = function(self, holder, value)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_number(value)
        println(get_id(holder) .. " " .. get_id(self) .. " on_hp_lost")
    end,

    on_healing_performed = function(self, holder, receiver, value)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_entity_proxy(receiver)
        assert_is_number(value)
        println(get_id(holder) .. " " .. get_id(self) .. " on_healing_performed")
    end,

    on_damage_dealt = function(self, holder, damage_taker, value)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_entity_proxy(receiver)
        assert_is_number(value)
        println(get_id(holder) .. " " .. get_id(self) .. " on_damage_dealt")
    end,

    on_status_gained = function(self, holder, gained_status)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_status_proxy(gained_status)
        println(get_id(holder) .. " " .. get_id(self) .. " on_status_gained")
    end,

    on_status_lost = function(self, holder, lost_status)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_status_proxy(lost_status)
        println(get_id(holder) .. " " .. get_id(self) .. " on_status_lost")
    end,

    on_global_status_gained = function(self, holder, global_status)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_global_status_proxy(global_status)
        println(get_id(holder) .. " " .. get_id(self) .. " on_global_status_gained")
    end,

    on_global_status_lost = function(self, holder, global_status)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_global_status_proxy(global_status)
        println(get_id(holder) .. " " .. get_id(self) .. " on_global_status_lost")
    end,

    on_knocked_out = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. " on_knocked_out")
    end,

    on_helped_up = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. " on_helped_up")
    end,

    on_killed = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. " on_killed")
    end,

    on_revived = function(self, holder)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        println(get_id(holder) .. " " .. get_id(self) .. " on_revived")
    end,

    on_swap = function(self, holder, entity_at_old_position)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(self)
        assert_is_entity_proxy(self)
        println(get_id(holder) .. " " .. get_id(self .. " on_swap"))
    end,

    on_move_used = function(self, holder, move, targets)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_move_proxy(move)
        for entity in values(targets) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(holder) .. " " .. get_id(self) .. " on_move_used")
    end,

    on_move_disabled = function(self, holder, move)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_move_proxy(move)
        println(get_id(holder) .. " " .. get_id(self) .. " on_move_disabled")
    end,

    on_consumable_consumed = function(self, holder, other)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(other)
        println(get_id(holder) .. " " .. get_id(self) .. " on_consumable_consumed")
    end,

    on_consumable_gained = function(self, holder, other)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(other)
        println(get_id(holder) .. " " .. get_id(self) .. " on_consumable_gained")
    end,

    on_consumable_lost = function(self, holder, other)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(other)
        println(get_id(holder) .. " " .. get_id(self) .. " on_consumable_lost")
    end,

    on_consumable_disabled = function(self, holder, other)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(other)
        println(get_id(holder) .. " " .. get_id(self) .. " on_consumable_disabled")
    end,

    on_entity_spawned  = function(self, holder, other_entity)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_entity_proxy(other_entity)
        println(get_id(holder) .. " " .. get_id(self) .. " on_entity_spawned")
    end,

    on_equip_disabled = function(self, holder, equip)
        assert_is_consumable_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_equip_proxy(equip)
        println(get_id(holder) .. " " .. get_id(self) .. "on_equip_disabled")
    end
}