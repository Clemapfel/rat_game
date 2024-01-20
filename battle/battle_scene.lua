--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", function(config)
    local out = meta.new(bt.BattleScene, {}, rt.Scene)
    return out
end)

--- @field log bt.BattleLog
bt.BattleScene.log = bt.BattleLog()

--- @field background bt.BattleBackground
bt.BattleScene.background = {}

--- @field entities Table<String, bt.Entity>
bt.BattleScene.entities = {}

--- @brief
function bt.BattleScene:get_entity(id)
    return self.entities[id]
end