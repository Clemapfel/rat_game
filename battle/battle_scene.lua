--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", function(config)
    local out = meta.new(bt.BattleScene, {
        _entites = {}   --- @field _entities Table<String, bt.Entity>
    }, rt.Scene)
    return out
end)

--[[
ActionClosures:
    + Start of Battle

    + Ally Appears
    + Enemy Appears
    + Enemy Sprite Changes

    + StatAlteration Increases
    + StatAlteration Lowers
    + StatAlteration reset to 0

    + HP increases
    + HP lowered

    + PP increases
    + PP lowered

    + HP reduced to 0
    + Entity knocked out
    + Entity helped up
    + Entity dies

    + StatusAilment gained
    + StatusAilment cured
    + StatusAilment effect applied

    + Move Applied
    + End of Battle
]]--

--- @brief
function bt.BattleScene:get_entity(id)
    return self.entities[id]
end

--- @brief
function bt.BattleScene:add_entity(id, is_enemy)

end