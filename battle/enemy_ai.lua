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
        local ai_level = self._state:entity_get_ai_level(entity)
        local valid_moves = self._state:entity_get_selectable_moves(entity)

        if #valid_moves == 0 then
            local move = bt.MoveConfig("STRUGGLE")
            local target = rt.random.choose(self._state:entity_get_valid_targets_for_move(entity, move))
            table.insert(choices, bt.MoveSelection(entity, move, target))
        else
            local move, targets
            if ai_level == bt.AILevel.RANDOM then
                move = rt.random.choose(valid_moves)
                targets = rt.random.choose(self._state:entity_get_valid_targets_for_move(entity, move))
            else
                rt.error("In bt.EnemyAI:make_move_selection: unhandled AI level `" .. level .. "`")
            end

            table.insert(choices, bt.MoveSelection(entity, move, targets))
        end
    end

    return choices
end

