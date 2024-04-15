return {
    name = "Debug Status",

    max_duration = POSITIVE_INFINITY,

    sprite_id = "status_ailment",
    sprite_index = 2,
    description = "Prints messages for every trigger payload",

    on_gained = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        println("[STATUS] In Status " .. self:get_id() .. ".on_gained: `" .. afflicted:get_id() .. "` gained `" .. self:get_id() .. "`")
        return nil
    end,

    on_lost = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        println("[STATUS] In Status " .. self:get_id() .. ".on_lost: `" .. afflicted:get_id() .. "` lost `" .. self:get_id() .. "`")
        return nil
    end,

    on_turn_start = function(self, afflicted)
        meta.assert_is_status_interface(self)
        meta.assert_is_entity_interface(afflicted)
        println("[STATUS] In Status " .. self:get_id() .. ".on_turn_start: `" .. afflicted:get_id() .. "` new turn start")
        return nil
    end,

    on_turn_end = function(afflicted)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " changed stance `" .. old_stance:get_id() .. "` to `" .. new_stance:get_id() .. "`")
        return nil
    end,

    on_battle_start = function(afflicted)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " battle start")
        return nil
    end,

    on_battle_end = function(afflicted)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " battle end")
        return nil
    end,

    on_damage_taken = function(afflicted, damage_dealer, damage)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, damage_dealer) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        meta.assert_number(damage)
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " takes `" .. tostring(damage) .. "` damage from `" .. damage_dealer:get_id() .. "`")
        return damage -- new damage
    end,

    on_damage_dealt = function(afflicted, damage_taker, damage)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, damage_taker) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        meta.assert_number(damage)
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " deals `" .. tostring(damage) .. "` damage to `" .. damage_taker:get_id() .. "`")
        return nil
    end,

    on_other_status_gained = function(afflicted, gained_status)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(gained_status, bt.Status)
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " gained other status `" .. gained_status:get_id() .. "`")
        return true -- allow applying status
    end,

    on_other_status_lost = function(afflicted, lost_status)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(lost_status, bt.Status)
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " lost other status `" .. lost_status:get_id() .. "`")
        return nil
    end,

    on_knocked_out = function(afflicted, knock_out_causer)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, knock_out_causer) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " was knocked out by `" .. knock_out_causer:get_id() .. "`")
        return true -- allow knock out
    end,

    on_helped_up = function(afflicted, help_up_causer)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " was helped up by `" .. help_up_causer:get_id() .. "`")
        return true -- allow help up
    end,

    on_death = function(afflicted, death_causer)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, death_causer) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " was killed by `" .. death_causer:get_id() .. "`")
        return true -- allow death
    end,

    on_switch = function(afflicted, entity_at_old_position)
        meta.asssert_isa(self, bt.Status)
        for entity in range(afflicted, entity_at_old_position) do
            meta.assert_isa(entity, bt.BattleEntity)
        end
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " switched positions with `" .. entity_at_old_position:get_id() .. "`")
        return true -- allow switch
    end,

    on_stance_change = function(afflicted, old_stance, new_stance)
        meta.assert_isa(self, bt.Status)
        for stance in range(old_stance, new_stance) do
            meta.assert_isa(stance, bt.Stance)
        end
        println("[STATUS][" .. self:get_id() .. "] " .. afflicted:get_id() .. " changed stance `" .. old_stance:get_id() .. "` to `" .. new_stance:get_id() .. "`")
        return true -- allow change
    end,

    on_before_move = function(afflicted, target, move_selection)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(target, bt.BattleEntity)
        meta.assert_isa(move_selection, bt.MoveSelection)
        -- TODO
        return true -- allow move
    end,

    on_after_move = function(afflicted, target, move_selection)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(target, bt.BattleEntity)
        meta.assert_isa(move_selection, bt.MoveSelection)
        -- TODO
        return nil
    end,

    on_before_consumable = function(afflicted, consumable)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(consumable, bt.Consumable)
        -- TODO
        return true -- allow consuming
    end,

    on_after_consumable = function(afflicted, consumable)
        meta.asssert_isa(self, bt.Status)
        meta.assert_isa(afflicted, bt.BattleEntity)
        meta.assert_isa(consumable, bt.Consumable)
        -- TODO
        return nil
    end,
}