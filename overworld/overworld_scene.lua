--- @class ow.OverworldScene
ow.OverworldScene = meta.new_type("OverworldScene", function()
    local out = meta.new(ow.OverworldScene, {
        _world = rt.PhysicsWorld(0, 0),
        _player_spawn_x = 0,
        _player_spawn_y = 0,
        _player = {},
        _entities = {}, -- Table<ow.OverworldEntitiy>
    })

    out._player = ow.Player(out._world, 0, 0)
    return out
end)

--- @brief
function ow.OverworldScene:realize()
    self._player:set_spawn_position(self._player_spawn_x, self._player_spawn_y)
    self._player:realize()
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
    self._player:draw()
end

--- @brief
function ow.OverworldScene:update(delta)
    self._world:update(delta)
    self._player:update(delta)
    -- entities are updated automatically through rt.Animation
end