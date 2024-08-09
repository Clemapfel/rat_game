--- @class rt.GameState
rt.GameState = meta.new_type("GameState", {
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
    ]]--
})

--- @brief
function rt.GameState:import_from_save_file(file)
    meta.assert_isa(file)
end

--- @brief
--- @return file
function rt.GameState:export_to_save_file()

end