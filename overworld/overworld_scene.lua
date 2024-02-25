rt.settings.overworld.overworld_scene = {
    player_render_priority = 0
}

--- @class ow.OverworldScene
ow.OverworldScene = meta.new_type("OverworldScene", function()
    local out = meta.new(ow.OverworldScene, {
        _world = rt.PhysicsWorld(0, 0),
        _player_spawn_x = 0,
        _player_spawn_y = 0,
        _player = {},
        _entities = {[0] = {}},             -- Table<RenderPriority, Table<ow.OverworldEntitiy>>
        _render_priorities_in_order = {0},  -- Table<RenderPriority> (sorted)
        _render_priorities_set = {[0] = true} -- Set<RenderPriority>
    })

    out._player = ow.Player(out._world, 0, 0)
    return out
end)

--- @brief
function ow.OverworldScene:realize()
    self._player:set_spawn_position(self._player_spawn_x, self._player_spawn_y)
    self._player:realize()

    for _, prio in ipairs(self._render_priorities_in_order) do
        for _, entity in pairs(self._entities[prio]) do
            entity:realize()
        end
    end
end

--- @brief
function ow.OverworldScene:add_entity(entity, x, y, render_priority)
    render_priority = which(render_priority, 0)

    if self._render_priorities_set[render_priority] ~= true then
        self._render_priorities_set[render_priority] = true
        table.insert(self._render_priorities_in_order, render_priority)
        table.sort(self._render_priorities_in_order)
    end

    if meta.is_nil(self._entities[render_priority]) then
        self._entities[render_priority] = {}
    end

    table.insert(self._entities[render_priority], entity)
    entity:set_position(which(x, 0), which(y, 0))
end

--- @brief
function ow.OverworldScene:draw()
    for _, prio in ipairs(self._render_priorities_in_order) do
        for _, entity in pairs(self._entities[prio]) do
            entity:draw()
        end
        if prio == 0 then self._player:draw() end
    end
end

--- @brief
function ow.OverworldScene:update(delta)
    self._world:update(delta)
    -- entities are updated automatically through rt.Animation
end