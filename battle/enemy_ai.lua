--- @class bt.EnemyAI
bt.EnemyAI = meta.new_type("EnemyAI", function(state)
    return meta.new(bt.EnemyAI, {
        _state = state
    })
end)

--- @brief
function bt.EnemyAI:make_move_selection(enemies)
    local choices = {}
    for entity in values(enemies) do
        local valid_moves = self:_get_valid_moves(entity)
        local move, targets
        if #valid_moves == 0 then
            move = bt.MoveConfig("STRUGGLE")
            targets = {entity}
        else
            local level = self._state:entity_get_ai_level(entity)
            if level == bt.AILevel.RANDOM then
                move = rt.random.choose(valid_moves)
                targets = rt.random.choose(self:_get_valid_targets(entity, move))
            else
                rt.error("In bt.EnemyAI:make_move_selection: unhandled AI level `" .. level .. "`")
            end
        end

        table.insert(choices, bt.MoveSelection(
            entity,
            move,
            targets
        ))
    end
end

--- @brief [internal]
--- @return Table<Table<bt.Entity>>
function bt.EnemyAI:_get_valid_targets(user, move)
    return self._state:entity_get_valid_targets_for_move(user, move)
end

function bt.EnemyAI:_get_valid_moves(entity)
    local moves = {}
    local n, slots = self._state:entity_list_move_slots(entity)
    for slot_i = 1, n do
        local move = self._state:entity_get_move(entity, slot_i)
        if move ~= nil then
            local n_left = move:get_max_n_uses() - self._state:entity_get_move_n_used(entity, slot_i)
            local is_disabled = self._state:entity_get_move_is_disabled(entity)
            if n_left > 0 and not is_disabled then
                table.insert(moves, move)
            end
        end
    end
    return moves
end

