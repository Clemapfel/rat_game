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
        local valid_moves = self._state:entity_get_selectable_moves(entity)
        local move, targets
        if #valid_moves == 0 then
            move = bt.MoveConfig("STRUGGLE")
            targets = {entity}
        else
            local level = self._state:entity_get_ai_level(entity)
            if level == bt.AILevel.RANDOM then
                move = rt.random.choose(valid_moves)
                targets = rt.random.choose(self._state:entity_get_valid_targets_for_move(entity, move))
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

    return choices
end

