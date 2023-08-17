--- @class BattleAction
rt.BattleAction = meta.new_type("Action", {
    --- @brief (rt.BattleScene) -> nil
    apply = meta.Function()
})
meta.set_constructor(rt.BattleAction, function (self, f)
    meta.assert_function(f, "BattleAction()", 1)
    local out = meta.new(rt.BattleAction)
    out.apply = f
    return out
end)

--- @class BattleScene
rt.BattleScene = meta.new_type("BattleScene", {

    id = "",
    weather = rt.NO_WEATHER,
    turn_count = 0,

    --- @brief id -> rt.Entity
    entities = meta.Table(),

    --- @brief order of entities
    entity_order = Queue(),

    --- @brief queue of battle actions
    action_queue = Queue(),
})
rt._current_scene = rt.BattleScene()

--- @brief id of all enemies
--- @param scene BattleScene
function rt.get_enemy_ids(scene)

    meta.assert_type(rt.BattleScene, scene)
    local out = {}
    for id, entity in pairs(scene.entities) do
        if entity.is_enemy == true then
            table.insert(id)
        end
    end

    return out
end

--- @brief id of party
--- @param scene BattleScene
function rt.get_party_ids(scene)

    meta.assert_type(rt.BattleScene, scene)
    local out = {}
    for id, entity in pairs(scene.entities) do
        if entity.is_enemy == false then
            table.insert(id)
        end
    end

    return out
end

--- @brief step simulation
function rt.step()
    local next = rt._current_scene.action_queue:pop_front();
    next.apply(rt._current_scene)
end

--- @brief determine turn order for next turn
function rt.determine_turn_order()

    local entities = rt._current_scene.entities

    local brackets = {}
    local priorities = {}

    for prio in pairs(rt.Priority) do
        table.insert(priorities, prio)
        brackets[prio] = {}
    end

    for entity in pairs(rt._current_scene.entities) do

        local prio = rt.get_priority(entity)
        table.insert(brackets[prio], entity.id)
    end

    local out = {}

    table.sort(priorities)
    for prio in priorities do
        local bracket = brackets[prio]
        table.sort(bracket, function(a, b)
            return rt.get_speed(a) < rt.get_speed(b)
        end)

        for _, v in pairs(bracket) do
            table.insert(out, v)
        end
    end

    return out
end