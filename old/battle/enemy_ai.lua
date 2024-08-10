--- @class bt.EnemyAI
bt.EnemyAI = meta.new_type("EnemyAI")() -- singleton

--- @brief
--- @param user bt.Entity
--- @param state bt.Battle
function bt.EnemyAI.choose(user, state)
    local level = user:get_ai_level()
    if level == bt.AILevel.RANDOM then
        return bt.EnemyAI._random(user, state)
    else
        rt.error("In bt.EnemyAI.choose: unhandled AI level `" .. user.ai_level .. "`")
    end
end

--- @brief [internal]
--- @return Table<Table<bt.Entity>>
function bt.EnemyAI._get_possible_targets(user, move, state)
    local is_party = user:get_is_enemy() == false
    local can_target_self = move:get_can_target_self()
    local can_target_enemies = (move:get_can_target_enemies() and is_party) or (move:get_can_target_allies() and not is_party)
    local can_target_party = (move:get_can_target_allies() and is_party) or (move:get_can_target_enemies() and not is_party)

    if move:get_can_target_multiple() then
        local targets = {}
        for entity in values(state:list_entities()) do
            if entity == user and can_target_self then
                table.insert(targets, entity)
            elseif entity:get_is_enemy() == true and can_target_enemies then
                table.insert(targets, entity)
            elseif entity:get_is_enemy() == false and can_target_party then
                table.insert(targets, entity)
            end
        end
        return {targets}
    else
        local targets = {}
        for entity in values(state:list_entities()) do
            if entity == user and can_target_self then
                table.insert(targets, {entity})
            elseif entity:get_is_enemy() == true and can_target_enemies then
                table.insert(targets, {entity})
            elseif entity:get_is_enemy() == false and can_target_party then
                table.insert(targets, {entity})
            end
        end
        return targets
    end
end

--- @brief [internal]
function bt.EnemyAI._random(user, state)
    local move = rt.random.choose(user:list_moves())
    local possible_targets = bt.EnemyAI._get_possible_targets(user, move, state)

    if move:get_can_target_multiple() == true then
        return bt.ActionChoice(
            user,
            move,
            possible_targets[1]
        )
    else
        return bt.ActionChoice(
            user,
            move,
            rt.random.choose(possible_targets)
        )
    end
end

