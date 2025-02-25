require "include"

require "common.game_state"

STATE = rt.GameState()

--[[
state = { -- Serializable Table, no functions or userdata
    # entities
    party[position_i] = {
        entity_id

        n_move_slots
        moves[slot_i] = {
            move_id
            n_times_used
        }

        n_consumable_slots
        consumables[slot_i] = {
            consumable_id
            n_stacks_left
        }

        equips[slot_i] = {
            equip_id
            n_times_used
        }

        status[slot_i] = {
            status_id
            n_turns_passed
        }

        simulation_state -- Table<BattleID, Table<ID, Value>>

        state -- bt.EntityState
        hp    -- Unsigned
    }

    # inventory
    shared_inventory = {
        moves  -- Table<MoveID, Count>
        equips -- Table<EquipID, Count>
        consumables -- Table<ConsumableID, Count>
    }

    templates[template_i] = {
        created_on  -- Date
        name
        setups[entity_id] = {
            moves[slot_i] = MoveID
            equips[slot_i] = EquipID
            consumables[slot_i] = ConsumableID
        }
    }

    # config
    config = {
        [rt.InputButton] = Table<love_key_id>,
        vsync   -- {-1, 0, 1}
        msaa    -- {0, 2, 4, 8, 16}
        resolution_x, resolution_y
    }

    input_mapping[rt.InputButton.A] = love.
}
    ]]--

state = mn.InventoryState()

rt.current_scene = mn.Scene()
scene = rt.current_scene

--- ###

love.load = function()
    if scene ~= nil then
        local state = mn.InventoryState()
        state.entities = {
            bt.Entity("MC"),
            bt.Entity("RAT"),
            bt.Entity("GIRL")
        }
        scene._state = state
        scene:realize()
    end
    love.resize()
end

love.draw = function()
    love.graphics.clear(0.3, 0, 0.3, 1)
    if scene ~= nil then
        scene:draw()
    end
end

love.update = function(delta)
    if scene ~= nil and scene.update ~= nil then
        scene:update(delta)
    end
end

love.resize = function()
    if scene ~= nil then
        scene:fit_into(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

love.run = function()
    STATE:run()
end