return {
    name = "Debug Status",
    description = "Prints message for every possible status trigger",
    flavor_text = "For debugging only",

    max_duration = POSITIVE_INFINITY,
    is_stun = false,

    sprite_id = "statuses",
    sprite_index = "DEBUG_STATUS",

    on_gained = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_gained")
    end,

    on_lost = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_lost")
    end,

    on_already_present = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_already_present")
    end,

    on_turn_start = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_turn_start")
    end,

    on_turn_end = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_turn_end")
    end,

    on_battle_start = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_battle_start")
    end,

    on_battle_end = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_battle_end")
    end,

    on_hp_gained = function(self, afflicted, value)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_number(value)
        println(get_id(self) .. " on_hp_gained")
    end,

    on_hp_lost = function(self, afflicted, value)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_number(value)
        println(get_id(self) .. " on_hp_lost")
    end,

    on_healing_performed = function(self, afflicted, receiver, value)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_entity_proxy(receiver)
        assert_is_number(value)
        println(get_id(self) .. " on_healing_performed")
    end,

    on_damage_dealt = function(self, afflicted, damage_taker, value)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_entity_proxy(damage_taker)
        assert_is_number(value)
        println(get_id(self) .. " on_damage_dealt")
    end,

    on_status_gained = function(self, afflicted, gained_status)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_status_proxy(gained_status)
        println(get_id(self) .. " on_status_gained")
    end,

    on_status_lost = function(self, afflicted, lost_status)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_status_proxy(lost_status)
        println(get_id(self) .. " on_status_lost")
    end,

    on_global_status_gained = function(self, afflicted, gained_status)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_global_status(gained_status)
        println(get_id(self) .. " on_global_status_gained")
    end,

    on_knocked_out = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_knocked_out")
    end,

    on_helped_up = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_helped_up")
    end,

    on_killed = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_killed")
    end,

    on_revived = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_revived")
    end,

    on_swap = function(self, afflicted, entity_at_old_position)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_entity_proxy(entity_at_old_position)
        println(get_id(self) .. "on_swap")
    end,

    on_move_used = function(self, afflicted, move, targets)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_move_proxy(move)
        for entity in values(targets) do
            assert_is_entity_proxy(targets)
        end
        println(get_id(self) .. " on_move_use")
    end,

    on_move_disabled = function(self, afflicted, moved)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_move_proxy(move)
        println(get_id(self) .. " on_move_disabled")
    end,

    on_consumable_consumed = function(self, afflicted, consumable)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_consumable_proxy(consumable)
        println(get_id(self) .. " on_consumable_consumed")
    end,

    on_consumable_gained = function(self, afflicted, consumable)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_consumable_proxy(consumable)
        println(get_id(self) .. " on_consumable_gained")
    end,

    on_consumable_lost = function(self, afflicted, consumable)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_consumable_proxy(consumable)
        println(get_id(self) .. " on_consumable_lost")
    end,

    on_consumable_disabled = function(self, afflicted, consumable)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_consumable_proxy(consumable)
        println(get_id(self) .. " on_consumable_disabled")
    end,

    on_entity_spawned = function(self, afflicted)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        println(get_id(self) .. " on_entity_spawned")
    end,

    on_equip_disabled = function(self, afflicted, equip)
        assert_is_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_equip_proxy(equip)
        println(get_id(self) .. " on_equip_disabled")
    end
}