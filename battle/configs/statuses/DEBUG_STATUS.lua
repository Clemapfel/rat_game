return {
    name = "Debug Status",

    max_duration = 3,
    is_silent = false,
    is_stun = true,

    attack_factor = 1,
    defense_factor = 1,
    speed_factor = 1,

    attack_offset = 0,
    defense_offset = 0,
    speed_offset = 123,

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
        println("[DBG] In " .. self.id .. ".on_lost: " .. afflicted.id .. " gained self")
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
        println("[DBG] In " .. self.id .. ".on_battle_end: battle ended while " .. afflicted.id .. " is afflicted")
        return nil
    end,

    on_healing_received = function(self, afflicted, value)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_number(value)
        println("[DBG] In " .. self.id .. ".on_healing_received: " .. self:get_id() .. " gained " .. value .. " hp")
        return nil
    end,

    on_healing_performed = function(self, afflicted, receiver, value)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(receiver)
        meta.assert_number(value)
        println("[DBG] In " .. self.id .. ".on_healing_performed: " .. afflicted:get_id() .. " restored " .. receiver:get_id() .. " for " .. value .. " hp")
        return nil
    end,

    on_damage_taken = function(self, afflicted, value)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_number(value)
        println("[DBG] In " .. self.id .. ".on_damage_taken: " .. self:get_id() .. " lost " .. value .. " hp")
        return nil
    end,

    on_damage_dealt = function(self, afflicted, receiver, value)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_entity_interface(receiver)
        meta.assert_number(value)
        println("[DBG] In " .. self.id .. ".on_damage_dealt: " .. afflicted:get_id() .. " damaged " .. receiver:get_id() .. " for " .. value .. " hp")
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

    on_move_used = function(self, afflicted_user, move, targets)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted_user)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_move_interface(target)
        end
        println("[DBG] In " .. self.id .. ".on_move_used: " .. afflicted_user.id .. " used " .. move.id)
        return nil
    end,

    on_consumable_consumed = function(self, afflicted, consumable)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_consumable_interface(consumable)
        println("[DBG] In " .. self.id .. ".on_consumable_consumed: " .. afflicted.id .. " consumed " .. consumable.id)
        return nil
    end,

    on_consumable_gained = function(self, afflicted, consumable)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_consumable_interface(consumable)
        println("[DBG] In " .. self.id .. ".on_consumable_gained: " .. afflicted.id .. " gained " .. consumable.id)
        return nil
    end,

    on_consumable_lost = function(self, afflicted, consumable)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_consumable_interface(consumable)
        println("[DBG] In " .. self.id .. ".on_consumable_lost: " .. afflicted.id .. "consumed " .. consumable.id)
        return nil
    end,

    on_entity_spawned = function(self, afflicted)
        meta.assert_status_interface(self)
        meta.assert_entity_interface(afflicted)
        println("[DBG] In " .. self.id .. ".on_entity_spanwed: " .. afflicted.id .. " joined")
        return nil
    end
}