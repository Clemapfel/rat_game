rt.settings.battle.enemy_sprite = {
    idle_animation_id = "idle",
    knocked_out_animation_id = "knocked_out"
}

--- @class bt.EnemySprite
bt.EnemySprite = meta.new_type("EnemySprite", rt.Widget, rt.Animation, bt.BattleAnimationTarget, function(scene, entity)
    return meta.new(bt.EnemySprite, {
        _entity = entity,
        _scene = scene,
        _is_realized = false,

        _sprite = rt.Sprite(entity.sprite_id),
        _snapshot = rt.SnapshotLayout(),

        _hp_bar = bt.HealthBar(scene, entity),
        _hp_bar_is_visible = true,

        _speed_value = bt.SpeedValue(entity),
        _speed_value_is_visible = true,

        _status_bar = bt.StatusBar(entity),
        _status_bar_is_visible = true,

        _debug_bounds = {}, -- rt.Rectangle
        _debug_sprite = {}, -- rt.Rectangle
        _ui_is_visible = true,
        _opacity = 1,
        _state = bt.BattleEntityState.ALIVE,

        _animation_queue = bt.AnimationQueue()
    })
end)

--- @override
function bt.EnemySprite:realize()
    if self._is_realized then return end
    self._is_realized = true

    local sprite_w, sprite_h = self._sprite:get_resolution()
    self._sprite:set_minimum_size(sprite_w * 4, sprite_h * 4)
    self._sprite:realize()
    self._sprite:set_is_animated(true)

    local animation_id = rt.settings.battle.enemy_sprite.idle_animation_id
    if self._sprite:has_animation(animation_id) then
        self._sprite:set_animation(animation_id)
    end

    self._hp_bar:realize()
    self._hp_bar:sync()

    self._speed_value:realize()
    self._speed_value:sync()

    self._status_bar:realize()
    self._status_bar:sync()

    self._snapshot = rt.SnapshotLayout()
    self._snapshot:realize()

    self:set_is_animated(true)
    self:reformat()
end

--- @brief
function bt.EnemySprite:sync()
    self._hp_bar:sync()
    self._speed_value:sync()
    self._status_bar:sync()
end

--- @override
function bt.EnemySprite:update(delta)

    self._hp_bar:update(delta)
    self._speed_value:update(delta)
    self._status_bar:update(delta)

    -- snapshot, can be modified by animations
    self._snapshot:snapshot(self._sprite)
end

--- @override
function bt.EnemySprite:size_allocate(x, y, width, height)
    self._sprite:fit_into(x, y, width, height)
    self._snapshot:fit_into(x, y, width, height)

    self._debug_bounds = rt.Rectangle(x, y, width, height)
    local sprite_x, sprite_y = self._sprite:get_position()
    local sprite_w, sprite_h = self._sprite:measure()

    self._debug_sprite = rt.Rectangle(sprite_x, sprite_y, sprite_w, sprite_h)

    local m = 0.5 * rt.settings.margin_unit
    local hp_bar_bounds = rt.AABB(sprite_x, sprite_y + sprite_h + m, sprite_w, rt.settings.battle.health_bar.hp_font:get_size() + 2 * m)

    hp_bar_bounds.x = hp_bar_bounds.x + rt.settings.margin_unit
    hp_bar_bounds.width = hp_bar_bounds.width - 2 * rt.settings.margin_unit -- why 2?
    self._hp_bar:fit_into(hp_bar_bounds)

    self._status_bar:fit_into(
        sprite_x, hp_bar_bounds.y + ternary(self._hp_bar_is_visible, hp_bar_bounds.height, 0),
        math.max(sprite_w, hp_bar_bounds.width), hp_bar_bounds.height
    )

    local speed_value_w, speed_value_h = self._speed_value:measure()
    self._speed_value:fit_into(
        sprite_x + sprite_w - speed_value_w * 1.5,
        sprite_y + sprite_h - speed_value_h
    )

    for debug in range(self._debug_bounds, self._debug_sprite) do
        debug:set_is_outline(true)
    end

    for _, animation in pairs(self._animation_queue.animations) do
        if animation:get_is_started() == true then
            animation:start()
        end
    end
end

--- @override
function bt.EnemySprite:measure()
    return self._sprite:measure()
end

--- @brief
function bt.EnemySprite:_draw()
    self._snapshot:draw()
    
    if self._ui_is_visible then
        if self._hp_bar_is_visible then self._hp_bar:draw() end
        if self._speed_value_is_visible then self._speed_value:draw() end
        if self._status_bar_is_visible then self._status_bar:draw() end
    end

    if self._scene:get_debug_draw_enabled() then
        self._debug_bounds:draw()
        self._debug_sprite:draw()
    end
end

--- @brief [internal]
function bt.EnemySprite:_draw_animations()
    self._animation_queue:draw()
end

--- @override
function bt.EnemySprite:draw()
    if self._is_realized then
        self:_draw()
        self._draw_animations()
    end
end

--- @override
function bt.EnemySprite:snapshot()
    local before = self._sprite:get_is_visible()
    self._sprite:set_is_visible(true)
    self._sprite:draw()
    self._sprite:set_is_visible(before)
end

--- @override
function bt.EnemySprite:set_is_visible(b)
    if self._is_realized then
        self._sprite:set_is_visible(b)
    end
end

--- @override
function bt.EnemySprite:get_is_visible()
    return self._sprite:get_is_visible()
end

--- @brief
function bt.EnemySprite:add_animation(animation)
    self._animation_queue:add_animation(animation)
end

--- @brief
function bt.EnemySprite:get_entity()
    return self._entity
end

--- @brief
function bt.EnemySprite:get_snapshot()
    return self._snapshot
end

--- @brief
function bt.EnemySprite:set_opacity(alpha)
    self._opacity = alpha
    self._sprite:set_opacity(alpha)
end

--- @brief
function bt.EnemySprite:set_ui_is_visible(b)
    self._ui_is_visible = b
end

--- @brief
function bt.EnemySprite:set_hp(value, value_max)
    self._hp_bar:set_value(value, value_max)
end

--- @brief
function bt.EnemySprite:add_status(status)
    self._status_bar:add(status, 0)
end

--- @brief
function bt.EnemySprite:activate_status(status)
    self._status_bar:activate(status)
end

--- @brief
function bt.EnemySprite:remove_status(status)
    self._status_bar:remove(status)
end

--- @brief
function bt.EnemySprite:set_priority(priority)
    -- noop for now
end

--- @brief
function bt.EnemySprite:set_state(state)
    self._state = state
    self._hp_bar:set_state(state)

    if state == bt.BattleEntityState.KNOCKED_OUT then
        self._sprite:set_animation(rt.settings.battle.enemy_sprite.knocked_out_animation_id)
    elseif state == bt.BattleEntityState.DEAD then
    else
        self._sprite:set_animation(rt.settings.battle.enemy_sprite.idle_animation_id)
    end
end

--- @brief
function bt.EnemySprite:get_scene()
    return self._scene
end

--- @brief
function bt.EnemySprite:get_entity()
    return self._entity
end