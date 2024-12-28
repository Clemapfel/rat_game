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
        println(string.concat(" ", get_id(self), "on_gained", table.unpack(entities)))
    end,

    on_lost = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(string.concat(" ", get_id(self), "on_lost", table.unpack(entities)))
    end,

    on_turn_start = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(string.concat(" ", get_id(self), "on_turn_start", table.unpack(entities)))
    end,

    on_turn_end = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(string.concat(" ", get_id(self), "on_turn_end", table.unpack(entities)))
    end,

    on_battle_start = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(string.concat(" ", get_id(self), "on_battle_start", table.unpack(entities)))
    end,

    on_battle_end = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(string.concat(" ", get_id(self), "on_battle_end", table.unpack(entities)))
    end,

    on_hp_gained = function(self, entity, value)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(entity)
        assert_is_number(value)
        println(string.concat(" ", get_id(self), "on_hp_gained", entity, value))
    end,

    on_hp_lost = function(self, entity, value)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(entity)
        assert_is_number(value)
        println(string.concat(" ", get_id(self), "on_hp_lost", entity, value))
    end,

    on_healing_performed = function(self, performer, receiver, value)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(performer)
        assert_is_entity_proxy(receiver)
        assert_is_number(value)
        println(string.concat(" ", get_id(self), "on_healing_performed", performer, receiver, value))
    end,

    on_damage_dealt = function(self, dealer, receiver, value)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(dealer)
        assert_is_entity_proxy(receiver)
        assert_is_number(value)
        println(string.concat(" ", get_id(self), "on_damage_dealt", dealer, receiver, value))
    end,

    on_status_gained = function(self, afflicted, status)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_status_proxy(status)
        println(string.concat(" ", get_id(self), "on_status_gained", afflicted, status))
    end,

    on_status_lost = function(self, afflicted, status)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(afflicted)
        assert_is_status_proxy(status)
        println(string.concat(" ", get_id(self), "on_status_lost", afflicted, status))
    end,

    on_global_status_gained = function(self, gained_status)
        assert_is_global_status_proxy(self)
        assert_is_global_status_proxy(gained_status)
        println(string.concat(" ", get_id(self), "on_global_status_gained", gained_status))
    end,

    on_global_status_lost = function(self, lost_status)
        assert_is_global_status_proxy(self)
        assert_is_global_status_proxy(lost_status)
        println(string.concat(" ", get_id(self), "on_global_status_lost", lost_status))
    end,

    on_knocked_out = function(self, knocked_out_entity)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(knocked_out_entity)
        println(string.concat(" ", get_id(self), "on_knocked_out", knocked_out_entity))
    end,

    on_helped_up = function(self, helped_up_entity)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(helped_up_entity)
        println(string.concat(" ", get_id(self), "on_helped_up", helped_up_entity))
    end,

    on_killed = function(self, killed_entity)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(killed_entity)
        println(string.concat(" ", get_id(self), "on_killed", killed_entity))
    end,

    on_revived = function(self, revived_entity)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(revived_entity)
        println(string.concat(" ", get_id(self), "on_revived", revived_entity))
    end,

    on_swap = function(self, a, b)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(a)
        assert_is_entity_proxy(b)
        println(string.concat(" ", get_id(self), "on_swap", a, b))
    end,
    
    on_move_used = function(self, move_user, move, targets)  
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(move_user)
        assert_is_move_proxy(move)
        for entity in values(targets) do
            assert_is_entity_proxy(entity)
        end
        println(string.concat(" ", get_id(self), "on_move_used", move_user, table.unpack(targets)))
    end,
    
    on_move_disabled = function(self, move_user, move)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(move_user)
        assert_is_move_proxy(move)
        println(string.concat(" ", get_id(self), "on_move_disabled", move_user, move))
    end,
    
    on_consumable_consumed = function(self, holder, consumable)  
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(consumable)
        println(string.concat(" ", get_id(self), "on_consumable_consumed", holder, consumable))
    end,

    on_consumable_gained = function(self, holder, consumable)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(consumable)
        println(string.concat(" ", get_id(self), "on_consumable_gained", holder, consumable))
    end,

    on_consumable_lost = function(self, holder, consumable)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(consumable)
        println(string.concat(" ", get_id(self), "on_consumable_lost", holder, consumable))
    end,

    on_consumable_disabled = function(self, holder, consumable)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_consumable_proxy(consumable)
        println(string.concat(" ", get_id(self), "on_consumable_disabled", holder, consumable))
    end,

    on_entity_spawned = function(self, entities)
        assert_is_global_status_proxy(self)
        for entity in values(entities) do
            assert_is_entity_proxy(entity)
        end
        println(string.concat(" ", get_id(self), "on_entity_spawned", table.unpack(entities)))
    end,

    on_equip_disabled = function(self, holder, equip)
        assert_is_global_status_proxy(self)
        assert_is_entity_proxy(holder)
        assert_is_equip_proxy(equip)
        println(string.concat(" ", get_id(self), "on_entity_spawned", holder, equip))
    end
}