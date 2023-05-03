--- @class BattleScene
rt.BattleScene = meta.new_type("BattleScene", {

    id = "",
    weather = rt.NO_WEATHER,
    turn_count = 0,

    --- @brief id -> rt.Entity
    entities = meta.Table(),
})

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