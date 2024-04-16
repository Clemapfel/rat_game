return {
    name = "Debug Consumable",

    max_n_uses = 3,

    sprite_id = "battle/consumables",
    sprite_index = "DEBUG_CONSUMABLE",
    description = "Prints messages for every trigger payload",

    on_turn_start = function(self, holder)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        return nil
    end,

    on_turn_end = function(self, holder)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        return nil
    end,

    on_battle_start = function(self, holder)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        return nil
    end,

    on_battle_end = function(self, holder)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        return nil
    end,

    on_before_damage_taken = function(self, holder, damage_dealer, damage)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_taken = function(self, holder, damage_dealer, damage)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return nil
    end,

    on_before_damage_dealt = function(self, holder, damage_taker, damage)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_dealt = function(self, holder, damage_taker, damage)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_number(damage)
        return nil
    end,

    on_status_gained = function(self, holder, gained_status)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_status_interface(gained_status)
        return nil
    end,

    on_status_lost = function(self, holder, lost_status)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_status_interface(lost_status)
        return nil
    end,

    on_knocked_out = function(self, holder, knock_out_causer)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_status_interface(knock_out_causer)
        return nil
    end,

    on_helped_up = function(self, holder, help_up_causer)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_status_interface(help_up_causer)
        return nil
    end,

    on_killed = function(self, holder, death_causer)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_status_interface(death_causer)
        return nil
    end,

    on_switch = function(self, holder, entity_at_old_position)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_entity_interface(entity_at_old_position)
        return nil
    end,

    on_stance_changed = function(self, holder, old_stance, new_stance)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_stance_interface(old_stance)
        meta.assert_is_stance_interface(new_stance)
        return nil
    end,

    on_before_move = function(self, holder, move, targets)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_move_interface(move)
        for target in values(targets) do
            meta.assert_is_move_interface(targets)
        end
        return true -- allow move
    end,

    on_after_move = function(self, holder, move, targets)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_move_interface(move)
        for target in values(targets) do
            meta.assert_is_move_interface(targets)
        end
        return nil
    end,

    on_before_consumable = function(self, holder, consumable)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_consumable_interface(consumable)
        return true -- allow consuming
    end,

    on_after_consumable = function(self, holder, consumable)
        meta.assert_is_consumable_interface(self)
        meta.assert_is_entity_interface(holder)
        meta.assert_is_consumable_interface(consumable)
        return nil
    end,
}