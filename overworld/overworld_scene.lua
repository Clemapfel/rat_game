--- @class ow.OverworldScene
ow.OverworldScene = meta.new_type("OverworldScene", function()
    local out = meta.new(ow.OverworldScene, {
        _entities = {},     -- Table<ow.OverworldEntitiy>
    })
    return out
end)

--- @brief
function ow.OverworldScene:realize()
    for _, entity in pairs(self._entities) do
        entity:realize()
    end
end

--- @brief
function ow.OverworldScene:add_entity(entity, x, y)
    table.insert(self._entities, entity)
    entity:set_position(which(x, 0), which(y, 0))
end

--- @brief
function ow.OverworldScene:draw()
    for _, entity in pairs(self._entities) do
        entity:draw()
    end
end

--- @brief
function ow.OverworldScene:update(delta)
    -- entities are updated automatically through rt.Animation
end