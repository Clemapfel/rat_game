return {
    name = "Debug Status",

    max_duration = POSITIVE_INFINITY,
    is_silent = false,

    sprite_id = "status_ailment",
    sprite_index = 2,
    description = "Prints messages for every trigger payload",

    on_gained = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_lost = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_turn_start = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_turn_end = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_battle_start = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_battle_end = function(self, entities)
        meta.assert_is_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_is_entity_interface(entity)
        end
        return nil
    end,

    on_before_damage_taken = function(self, damage_taker, damage_dealer, damage)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_taken = function(self, damage_taker, damage_dealer, damage)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return nil
    end,

    on_before_damage_dealt = function(self, damage_dealer, damage_taker, damage)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_dealt = function(self, damage_dealer, damage_taker, damage)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_number(damage)
        return nil
    end,

    on_status_gained = function(self, afflicted, gained_status)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_status_interface(gained_status)
        return nil
    end,

    on_status_lost = function(self, afflicted, lost_status)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_status_interface(lost_status)
        return nil
    end,

    on_global_status_gained = function(self, gained_status)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_global_status_interface(gained_status)
        return nil
    end,

    on_global_status_lost = function(self, lost_status)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_global_status_interface(lost_status)
        return nil
    end,

    on_knocked_out = function(self, knocked_out_entity, knock_out_causer)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(knocked_out_entity)
        meta.assert_is_status_interface(knock_out_causer)
        return nil
    end,

    on_helped_up = function(self, helped_up_entity, help_up_causer)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(helped_up_entity)
        meta.assert_is_status_interface(help_up_causer)
        return nil
    end,

    on_killed = function(self, killed_entity, death_causer)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(killed_entity)
        meta.assert_is_status_interface(death_causer)
        return nil
    end,

    on_switch = function(self, switched_entity, entity_at_old_position)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(switched_entity)
        meta.assert_is_entity_interface(entity_at_old_position)
        return nil
    end,

    on_stance_changed = function(self, stance_changer, old_stance, new_stance)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(stance_changer)
        meta.assert_is_stance_interface(old_stance)
        meta.assert_is_stance_interface(new_stance)
        return nil
    end,

    on_before_move = function(self, move_user, move, targets)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(move_user)
        meta.assert_is_move_interface(move)
        for target in values(targets) do
            meta.assert_is_move_interface(targets)
        end
        return true -- allow move
    end,

    on_after_move = function(self, move_user, move, targets)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(move_user)
        meta.assert_is_move_interface(move)
        for target in values(targets) do
            meta.assert_is_move_interface(targets)
        end
        return nil
    end,

    on_before_consumable = function(self, holder, consumable)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_consumable_interface(consumable)
        return true -- allow consuming
    end,

    on_after_consumable = function(self, holder, consumable)
        meta.assert_is_global_status_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_consumable_interface(consumable)
        return nil
    end,
}