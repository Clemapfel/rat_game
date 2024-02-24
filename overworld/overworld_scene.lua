--- @class ow.OverworldScene
ow.OverworldScene = meta.new_type("OverworldScene", function()
    -- redundant tables for faster access and optimization
    local out = meta.new(ow.OverworldScene, {
        _entities = {},     -- Table<ow.OverworldEntitiy>
        _to_update = {},    -- Table<ow.OverEntity>
    })

    meta.make_weak(out._to_update, true, true)
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
    if meta.isa(entity, rt.Animation) then
        table.insert(self._to_update, entity)
    end
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
    for _, entity in pairs(self._to_update) do
        entity:update(delta)
    end
end