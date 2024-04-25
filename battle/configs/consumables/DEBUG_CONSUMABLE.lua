return {
    name = "Debug Consumable",

    max_n_uses = 3,

    sprite_id = "battle/consumables",
    sprite_index = "DEBUG_CONSUMABLE",
    description = "Prints messages for every trigger payload",

    on_turn_start = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        println("[DBG] In " .. self.id .. ".on_turn_start: start turn held by " .. holder.id)
        return nil
    end,

    on_turn_end = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        println("[DBG] In " .. self.id .. ".on_turn_end: end turn held by " .. holder.id)
        return nil
    end,

    on_battle_end = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        println("[DBG] In " .. self.id .. ".on_battle_end: battle ended held by " .. holder.id)
        return nil
    end,

    on_before_damage_taken = function(self, holder, damage_dealer, damage)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_entity_interface(damage_dealer)
        meta.assert_number(damage)
        println("[DBG] In " .. self.id .. ".on_before_damage_taken: " .. holder.id .. " will take " .. damage .. " damage from " .. damage_dealer)
        return damage -- new damage
    end,

    on_after_damage_taken = function(self, holder, damage_dealer, damage)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_entity_interface(damage_dealer)
        meta.assert_number(damage)
        println("[DBG] In " .. self.id .. ".on_after_damage_taken: " .. holder.id .. " took " .. damage .. " damage from " .. damage_dealer)
        return nil
    end,

    on_before_damage_dealt = function(self, holder, damage_taker, damage)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_entity_interface(damage_taker)
        meta.assert_number(damage)
        println("[DBG] In " .. self.id .. ".on_before_damage_dealt: " .. holder.id .. " will deal " .. damage .. " damage to " .. damage_taker)
        return damage -- new damage
    end,

    on_after_damage_dealt = function(self, holder, damage_taker, damage)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_entity_interface(damage_taker)
        println("[DBG] In " .. self.id .. ".on_after_damage_dealt: " .. holder.id .. " dealt " .. damage .. " damage to " .. damage_taker)
        meta.assert_number(damage)
        return nil
    end,

    on_status_gained = function(self, holder, gained_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_status_interface(gained_status)
        println("[DBG] In " .. self.id .. ".on_status_gained: " .. holder.id .. " gained " .. gained_status.id)
        return nil
    end,

    on_status_lost = function(self, holder, lost_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_status_interface(lost_status)
        println("[DBG] In " .. self.id .. ".on_status_lost: " .. holder.id .. " lost " .. lost_status.id)
        return nil
    end,

    on_global_status_gained = function(self, holder, gained_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_global_status_interface(gained_status)
        println("[DBG] In " .. self.id .. ".on_global_status_gained: " .. holder.id .. " held self when " .. gained_status.id .. " was added")
        return nil
    end,

    on_global_status_lost = function(self, holder, lost_status)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_global_status_interface(lost_status)
        println("[DBG] In " .. self.id .. ".on_global_status_gained: " .. holder.id .. " held self when " .. lost_status.id .. " was lost")
        return nil
    end,

    on_knocked_out = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        println("[DBG] In " .. self.id .. ".on_knocked_out: " .. holder.id .. " was knocked out")
        return nil
    end,

    on_helped_up = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        println("[DBG] In " .. self.id .. ".on_helped_up: " .. holder.id .. " was helped up by")
        return nil
    end,

    on_killed = function(self, holder)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        println("[DBG] In " .. self.id .. ".on_killed: " .. holder.id .. " was killed")
        return nil
    end,

    on_switch = function(self, holder, entity_at_old_position)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_entity_interface(entity_at_old_position)
        println("[DBG] In " .. self.id .. ".on_switch: " .. holder.id .. " switched positions with " .. entity_at_old_position.id)
        return nil
    end,

    on_stance_changed = function(self, holder, old_stance, new_stance)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_stance_interface(old_stance)
        meta.assert_stance_interface(new_stance)
        println("[DBG] In " .. self.id .. ".on_stance_changed: " .. holder.id .. " changed stance from " .. old_stance .. " to " .. new_stance)
        return nil
    end,

    on_before_move = function(self, holder, move, targets)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_move_interface(targets)
        end
        return true -- allow move
    end,

    on_after_move = function(self, holder, move, targets)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_move_interface(targets)
        end
        return nil
    end,

    on_consumable_consumed = function(self, holder, consumable)
        meta.assert_consumable_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_consumable_interface(consumable)
        println("[DBG] In " .. self.id .. ".on_before_consumable: " .. holder.id .. " is consumed " .. consumable.id)
        return nil
    end,
}