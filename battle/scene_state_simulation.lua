rt.settings.battle.scene.simulation = {
    skip_button = rt.InputButton.B,
    fast_forward_button = rt.InputButton.R,
    fast_forward_factor = 4
}

--- @class bt.SceneState.SIMULATION
bt.SceneState.SIMULATION = meta.new_type("SIMULATION", bt.SceneState, function(scene)
    local out = meta.new(bt.SceneState.SIMULATION, {
        _scene = scene,
        _fast_forward_active = false
    })

    return out
end)

--- @override
function bt.SceneState.SIMULATION:enter()
end

--- @override
function bt.SceneState.SIMULATION:exit()
end

--- @override
function bt.SceneState.SIMULATION:handle_button_pressed(button)
    local settings = rt.settings.battle.scene.simulation
    local scene = self._scene
    if button == settings.skip_button then
        scene:skip()
    elseif button == settings.fast_forward_button then
        if scene._animation_queue:get_is_empty() == false then
            self._fast_forward_active = true
        end
    elseif button == rt.InputButton.Y then
        self._scene:transition(bt.SceneState.INSPECT)
    end
end

--- @override
function bt.SceneState.SIMULATION:handle_button_released(button)
    local settings = rt.settings.battle.scene.simulation
    if button == rt.InputButton.B then
        self._scene:skip()
    elseif button == rt.InputButton.R then
        self._fast_forward_active = false
    end
end

--- @override
function bt.SceneState.SIMULATION:update(delta)
    local scene = self._scene

    for sprite in values(scene._party_sprites) do
        sprite:update(delta)
    end

    for sprite in values(scene._enemy_sprites) do
        sprite:update(delta)
    end

    local ff_delta = delta
    if self._fast_forward_active then
        ff_delta = delta * rt.settings.battle.scene.simulation.fast_forward_factor
    end

    scene._global_status_bar:update(ff_delta)
    scene._animation_queue:update(ff_delta)
    scene._priority_queue:update(ff_delta)
    scene._log:update(ff_delta)

    if self._fast_forward_active == true then
        scene._fast_forward_indicator:update(delta)
        if scene._animation_queue:get_is_empty() == true then
            self._fast_forward_active = false
        end
    end
end

--- @override
function bt.SceneState.SIMULATION:draw()
    local scene = self._scene

    for i in values(scene._enemy_sprite_render_order) do
        scene._enemy_sprites[i]:draw()
    end

    for sprite in values(scene._party_sprites) do
        sprite:draw()
    end

    scene._global_status_bar:draw()
    scene._priority_queue:draw()
    scene._animation_queue:draw()

    for i in values(scene._enemy_sprite_render_order) do
        bt.BattleSprite.draw(scene._enemy_sprites[i])
    end

    scene._log:draw()

    if self._fast_forward_active == true then
        scene._fast_forward_indicator:draw()
    end
end