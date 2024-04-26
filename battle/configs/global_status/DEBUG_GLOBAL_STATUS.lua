return {
    name = "Debug Status",

    max_duration = POSITIVE_INFINITY,
    is_silent = false,

    sprite_id = "status_ailment",
    sprite_index = 2,
    description = "Prints messages for every trigger payload",

    on_gained = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end

        local ids = ""
        for entity in values(entities) do
            ids = ids .. entity.id .. " "
            entity:add_status("DEBUG_STATUS")
        end
        println("[DBG] In " .. self.id .. ".on_gained: applied to ", ids)
        return nil
    end,

    on_lost = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        local ids = ""
        for entity in values(entities) do
            ids = ids .. entity.id .. " "
        end
        println("[DBG] In " .. self.id .. ".on_lost: applied to ", ids)
        return nil
    end,

    on_turn_start = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        local ids = ""
        for entity in values(entities) do
            ids = ids .. entity.id .. " "
        end
        println("[DBG] In " .. self.id .. ".on_turn_start: applied to ", ids)
        return nil
    end,

    on_turn_end = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        local ids = ""
        for entity in values(entities) do
            ids = ids .. entity.id .. " "
        end
        println("[DBG] In " .. self.id .. ".on_turn-end: applied to ", ids)
        return nil
    end,

    on_battle_end = function(self, entities)
        meta.assert_global_status_interface(self)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end
        local ids = ""
        for entity in values(entities) do
            ids = ids .. entity.id .. " "
        end
        println("[DBG] In " .. self.id .. ".on_battle_end: applied to ", ids)
        return nil
    end,

    on_hp_gained = function(self, entity, hp_gained)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(entity)
        meta.assert_number(hp_gained)
        println("[DBG] In " .. self.id .. ".on_hp_gained: " .. self:get_id() .. " gained " .. hp_gained .. " hp")
        return nil
    end,

    on_status_gained = function(self, afflicted, gained_status)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_status_interface(gained_status)
        println("[DBG] In " .. self.id .. ".on_status_gained: " .. afflicted.id .. " gained " .. gained_status.id)
        return nil
    end,

    on_status_lost = function(self, afflicted, lost_status)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(afflicted)
        meta.assert_status_interface(lost_status)
        println("[DBG] In " .. self.id .. ".on_status_lost: " .. afflicted.id .. " lost " .. lost_status.id)
        return nil
    end,

    on_global_status_gained = function(self, gained_status, entities)
        meta.assert_global_status_interface(self)
        meta.assert_global_status_interface(gained_status)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end

        local ids = ""
        for entity in values(entities) do
            ids = ids .. entity.id .. " "
        end
        println("[DBG] In " .. self.id .. ".on_global_status_gained: global status ", gained_status.id, " gained for " .. ids)
        return nil
    end,

    on_global_status_lost = function(self, lost_status, entities)
        meta.assert_global_status_interface(self)
        meta.assert_global_status_interface(gained_status)
        for entity in values(entities) do
            meta.assert_entity_interface(entity)
        end

        local ids = ""
        for entity in values(entities) do
            ids = ids .. entity.id .. " "
        end
        println("[DBG] In " .. self.id .. ".on_global_status_lost: global status ", lost_status.id, " gained for " .. ids)
        return nil
    end,

    on_knocked_out = function(self, knocked_out_entity)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(knocked_out_entity)
        println("[DBG] In " .. self.id .. ".on_knocked_out: " .. knocked_out_entity.id .. " was knocked out")
        return nil
    end,

    on_helped_up = function(self, helped_up_entity)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(helped_up_entity)
        println("[DBG] In " .. self.id .. ".on_helped_up: " .. helped_up_entity.id .. " was helped up")
        return nil
    end,

    on_killed = function(self, killed_entity)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(killed_entity)
        println("[DBG] In " .. self.id .. ".on_killed: " .. killed_entity.id .. " was killed")
        return nil
    end,

    on_switch = function(self, switched_entity, entity_at_old_position)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(switched_entity)
        meta.assert_entity_interface(entity_at_old_position)
        println("[DBG] In " .. self.id .. ".on_switch: " .. switched_entity.id .. " switched positions with " .. entity_at_old_position.id)
        return nil
    end,

    on_stance_changed = function(self, stance_changer, old_stance, new_stance)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(stance_changer)
        meta.assert_string(old_stance)
        meta.assert_string(new_stance)
        println("[DBG] In " .. self.id .. ".on_stance_changed: " .. stance_changer.id .. " changed stance from " .. old_stance .. " to " .. new_stance)
        return nil
    end,

    on_move = function(self, move_user, move, targets)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(move_user)
        meta.assert_move_interface(move)
        for target in values(targets) do
            meta.assert_entity_interface(target)
        end
        println("[DBG] In " .. self.id .. ".on_move: " .. move_user:get_id() .. " used move " .. move:get_id() .. "")
        return nil
    end,

    on_consumable_consumed = function(self, holder, consumable)
        meta.assert_global_status_interface(self)
        meta.assert_entity_interface(holder)
        meta.assert_consumable_interface(consumable)
        println("[DBG] In " .. self.id .. ".on_consumable_consumed: " .. holder.id .. " consumed " .. consumable.id)
        return nil
    end,

}