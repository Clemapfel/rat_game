rt.settings.overworld.overworld_scene = {
    player_render_priority = 0
}

--- @class ow.OverworldScene
ow.OverworldScene = meta.new_type("OverworldScene", function()
    local out = meta.new(ow.OverworldScene, {
        _world = rt.PhysicsWorld(0, 0),
        _debug_draw_enabled = true,
        _stages = {},    -- Table<ow.Stage>
        _player = {},
        _camera = ow.Camera(),
        _entities = {[0] = {}},             -- Table<RenderPriority, Table<ow.OverworldEntitiy>>
        _render_priorities_in_order = {0},  -- Table<RenderPriority> (sorted)
        _render_priorities_set = {[0] = true} -- Set<RenderPriority>
    })

    out._player = ow.Player(out, 0, 0)
    return out
end)

--- @brief
function ow.OverworldScene:realize()
    for _, stage in pairs(self._stages) do
        stage:realize()
    end
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
    if not meta.is_nil(x) and not meta.is_nil(y) then
        entity:set_position(x, y)
    end
end

--- @brief
function ow.OverworldScene:add_stage(name, prefix)
    prefix = which(prefix, "assets/stages")
    local stage = ow.Stage(rt.current_scene._world, name, prefix)
    table.insert(self._stages, stage)
end


--- @brief
function ow.OverworldScene:draw()
    self._camera:center_on(self._player:get_position())
    self._camera:bind()

    for _, stage in pairs(self._stages) do
        stage:draw()
    end

    for _, prio in ipairs(self._render_priorities_in_order) do
        for _, entity in pairs(self._entities[prio]) do
            entity:draw()
        end
        if prio == 0 then self._player:draw() end
    end
    self._camera:unbind()
end

--- @brief
function ow.OverworldScene:update(delta)
    self._world:update(delta)
    self._camera:update(delta)
    -- entities are updated automatically through rt.Animation
end

--- @brief
function ow.OverworldScene:get_debug_draw_enabled()
    return self._debug_draw_enabled
end

--- @brief
function ow.OverworldScene:set_debug_draw_enabled(b)
    self._debug_draw_enabled = b
end