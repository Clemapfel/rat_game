return {
    name = "Debug Status",

    max_duration = POSITIVE_INFINITY,
    is_silent = false,

    attack_factor = 1,
    defense_factor = 1,
    speed_factor = 1,

    attack_offset = 0,
    defense_offset = 0,
    speed_offset = 0,

    sprite_id = "status_ailment",
    sprite_index = 2,
    description = "Prints messages for every trigger payload",

    on_gained = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        return nil
    end,

    on_lost = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        return nil
    end,

    on_turn_start = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        return nil
    end,

    on_turn_end = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        return nil
    end,

    on_battle_start = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        return nil
    end,

    on_battle_end = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        return nil
    end,

    on_before_damage_taken = function(self, afflicted, damage_dealer, damage)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_taken = function(self, afflicted, damage_dealer, damage)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_entity_interface(damage_dealer)
        meta.assert_number(damage)
        return nil
    end,

    on_before_damage_dealt = function(self, afflicted, damage_taker, damage)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_number(damage)
        return damage -- new damage
    end,

    on_after_damage_dealt = function(self, afflicted, damage_taker, damage)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_entity_interface(damage_taker)
        meta.assert_number(damage)
        return nil
    end,

    on_status_gained = function(self, afflicted, gained_status)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_status_interface(gained_status)
        return nil
    end,

    on_status_lost = function(self, afflicted, lost_status)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_status_interface(lost_status)
        return nil
    end,

    on_global_status_gained = function(self, afflicted, gained_status)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_global_status_interface(gained_status)
        return nil
    end,

    on_global_status_lost = function(self, afflicted, lost_status)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_global_status_interface(lost_status)
        return nil
    end,

    on_knocked_out = function(self, afflicted, knock_out_causer)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_status_interface(knock_out_causer)
        return nil
    end,

    on_helped_up = function(self, afflicted, help_up_causer)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_status_interface(help_up_causer)
        return nil
    end,

    on_killed = function(self, afflicted, death_causer)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_status_interface(death_causer)
        return nil
    end,

    on_switch = function(self, afflicted, entity_at_old_position)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_entity_interface(entity_at_old_position)
        return nil
    end,

    on_stance_changed = function(self, afflicted, old_stance, new_stance)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_stance_interface(old_stance)
        meta.assert_is_stance_interface(new_stance)
        return nil
    end,

    on_before_move = function(self, afflicted, move, targets)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_move_interface(move)
        for target in values(targets) do
            meta.assert_is_move_interface(targets)
        end
        return true -- allow move
    end,

    on_after_move = function(self, afflicted, move, targets)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_move_interface(move)
        for target in values(targets) do
            meta.assert_is_move_interface(targets)
        end
        return nil
    end,

    on_before_consumable = function(self, afflicted, consumable)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_consumable_interface(consumable)
        return true -- allow consuming
    end,

    on_after_consumable = function(self, afflicted, consumable)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        meta.assert_is_consumable_interface(consumable)
        return nil
    end,
}