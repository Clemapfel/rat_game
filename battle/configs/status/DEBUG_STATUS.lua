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
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        println("[DBG] In " .. self.id .. ".on_gained: " .. afflicted.id .. " gained self")
        return nil
    end,

    on_lost = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        println("[DBG] In " .. self.id .. ".on_gained: " .. afflicted.id .. " gained self")
        return nil
    end,

    on_turn_start = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        println("[DBG] In " .. self.id .. ".on_turn_start: start turn while " .. afflicted.id .. " is afflicted")
        return nil
    end,

    on_turn_end = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        println("[DBG] In " .. self.id .. ".on_turn_end: end turn while " .. afflicted.id .. " is afflicted")
        return nil
    end,

    on_battle_end = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        println("[DBG] In " .. self.id .. ".on_battle_end: battle ended while " .. holder.id .. " is afflicted")
        return nil
    end,

    on_before_damage_taken = function(self, afflicted, damage_dealer, damage)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(damage_dealer)
        meta.assert_number(damage)
        println("[DBG] In " .. self.id .. ".on_before_damage_taken: " .. afflicted.id .. " will take " .. damage .. " damage from " .. damage_dealer)
        return damage -- new damage
    end,

    on_after_damage_taken = function(self, afflicted, damage_dealer, damage)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(damage_dealer)
        meta.assert_number(damage)
        println("[DBG] In " .. self.id .. ".on_after_damage_taken: " .. afflicted.id .. " took " .. damage .. " damage from " .. damage_dealer)
        return nil
    end,

    on_before_damage_dealt = function(self, afflicted, damage_taker, damage)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(damage_taker)
        meta.assert_number(damage)
        println("[DBG] In " .. self.id .. ".on_before_damage_dealt: " .. afflicted.id .. " will deal " .. damage .. " damage to " .. damage_taker)
        return damage -- new damage
    end,

    on_after_damage_dealt = function(self, afflicted, damage_taker, damage)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(damage_taker)
        meta.assert_number(damage)
        println("[DBG] In " .. self.id .. ".on_after_damage_dealt: " .. afflicted.id .. " dealt " .. damage .. " damage to " .. damage_taker)
        return nil
    end,

    on_status_gained = function(self, afflicted, gained_status)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_status_interface(gained_status)
        println("[DBG] In " .. self.id .. ".on_status_gained: " .. afflicted.id .. " gained other status " .. gained_status.id)
        return nil
    end,

    on_status_lost = function(self, afflicted, lost_status)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_status_interface(lost_status)
        println("[DBG] In " .. self.id .. ".on_status_lost: " .. afflicted.id .. " lost " .. lost_status.id)
        return nil
    end,

    on_global_status_gained = function(self, afflicted, gained_status)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_global_status_interface(gained_status)
        println("[DBG] In " .. self.id .. ".on_global_status_gained: " .. afflicted.id .. " was afflicted by self when " .. gained_status.id .. " was added")
        return nil
    end,

    on_global_status_lost = function(self, afflicted, lost_status)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_global_status_interface(lost_status)
        println("[DBG] In " .. self.id .. ".on_global_status_gained: " .. afflicted.id .. " was afflicted by self when " .. lost_status.id .. " was lost")
        return nil
    end,

    on_knocked_out = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        println("[DBG] In " .. self.id .. ".on_knocked_out: " .. afflicted.id .. " was knocked out")
        return nil
    end,

    on_helped_up = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        println("[DBG] In " .. self.id .. ".on_helped_up: " .. afflicted.id .. " was helped up")
        return nil
    end,

    on_killed = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        println("[DBG] In " .. self.id .. ".on_killed: " .. afflicted.id .. " was killed")
        return nil
    end,

    on_switch = function(self, afflicted, entity_at_old_position)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(entity_at_old_position)
        println("[DBG] In " .. self.id .. ".on_switch: " .. afflicted.id .. " switched positions with " .. entity_at_old_position.id)
        return nil
    end,

    on_stance_changed = function(self, afflicted, old_stance, new_stance)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_stance_interface(old_stance)
        meta.assert_stance_interface(new_stance)
        println("[DBG] In " .. self.id .. ".on_stance_changed: " .. afflicted.id .. " changed stance from " .. old_stance .. " to " .. new_stance)
        return nil
    end,

    on_before_move = function(self, afflicted, move, targets)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_move_interface(targets)
        end
        return true -- allow move
    end,

    on_after_move = function(self, afflicted, move, targets)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_move_interface(targets)
        end
        return nil
    end,

    on_consumable_consumed = function(self, afflicted, consumable)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_consumable_interface(consumable)
        println("[DBG] In " .. self.id .. ".on_consumable_consumed: " .. afflicted.id .. "consumed " .. consumable.id)
        return nil
    end,
}