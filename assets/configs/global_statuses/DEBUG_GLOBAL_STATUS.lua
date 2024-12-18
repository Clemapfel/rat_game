return {
    name = "Debug Global Status",
    description = "Prints message for every global status trigger",
    flavor_text = "And in today weather forecast: <debug>",

    sprite_id = "global_statuses",
    sprite_index = "DEBUG_GLOBAL_STATUS",

    max_duration = POSITIVE_INFINITY,

    on_gained = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(self) .. " on_gained")
    end,

    on_lost = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(self) .. " on_lost")
    end,

    on_turn_start = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(self) .. " on_turn_start")
    end,

    on_turn_end = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(self) .. " on_turn_end")
    end,

    on_battle_start = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(self) .. " on_battle_start")
    end,

    on_battle_end = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(self) .. " on_battle_end")
    end,

    on_hp_gained = function(self, entity, value)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(entity)
        assert_is_number(value)
        println(get_id(self) .. " on_hp_gained")
    end,

    on_hp_lost = function(self, entity, value)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(entity)
        assert_is_number(value)
        println(get_id(self) .. " on_hp_lost")
    end,

    on_healing_performed = function(self, performer, receiver, value)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(performer)
        assert_is_entity_proxy(receiver)
        assert_is_number(value)
        println(get_id(self) .. "on_healing_performed")
    end,

    on_damage_dealt = function(self, dealer, receiver, value)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(dealer)
        assert_is_entity_proxy(receiver)
        assert_is_number(value)
        println(get_id(self) .. "on_damage_dealt")
    end,

    on_status_gained = function(self, afflicted, status)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_status_proxy(status)
        println(get_id(self) .. " on_status_gained")
    end,

    on_status_lost = function(self, afflicted, status)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_status_proxy(status)
        println(get_id(self) .. " on_status_lost")
    end,

    on_global_status_gained = function(self, gained_status)
        assert_is_global_status_proxy(self)
        assert_is_global_status_proxy(gained_status)
        println(get_id(self) .. " on_global_status_gained")
    end,

    on_global_status_lost = function(self, gained_status)
        assert_is_global_status_proxy(self)
        assert_is_global_status_proxy(gained_status)
        println(get_id(self) .. " on_global_status_lost")
    end,

    on_knocked_out = function(self, knocked_out_entity)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(knocked_out_entity)
        println(get_id(self) .. " on_knocked_out")
    end,

    on_helped_up = function(self, knocked_out_entity)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(knocked_out_entity)
        println(get_id(self) .. " on_helped_up")
    end,

    on_killed = function(self, knocked_out_entity)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(knocked_out_entity)
        println(get_id(self) .. " on_killed")
    end,

    on_revived = function(self, knocked_out_entity)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(knocked_out_entity)
        println(get_id(self) .. " on_revived")
    end,

    on_swap = function(self, a, b)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(a)
        assert_is_entity_proxy(b)
        println(get_id(self) .. " on_swap")
    end,
    
    on_move_used = function(self, move_user, move, targets)  
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(move_user)
        assert_is_move_proxy(move)
        for entity in values(targets) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(self) .. " on_move_used")
    end,
    
    on_move_disabled = function(self, move_user, move)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(move_user)
        assert_is_move_proxy(move)
        println(get_id(self) .. " on_move_disabled")
    end,
    
    on_consumable_consumed = function(self, holder, consumable)  
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(consumable)
        println(get_id(self) .. " on_consumable_consumed")
    end,

    on_consumable_gained = function(self, holder, consumable)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(consumable)
        println(get_id(self) .. " on_consumable_gained")
    end,

    on_consumable_lost = function(self, holder, consumable)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(consumable)
        println(get_id(self) .. " on_consumable_lost")
    end,

    on_consumable_disabled = function(self, holder, consumable)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(consumable)
        println(get_id(self) .. " on_consumable_disabled")
    end,

    on_entity_spawned = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(get_id(self) .. " on_entity_spawned")
    end,

    on_equip_disabled = function(self, holder, equip)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_equip_proxy(equip)
        println(get_id(self) .. " on_equip_disabled")
    end
}