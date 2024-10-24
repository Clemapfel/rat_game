rt.settings.battle.enemy_sprite = {
    stunned_animation_width_to_height_ratio = 0.1
}

--- @class bt.EnemySprite
bt.EnemySprite = meta.new_type("EnemySprite", bt.EntitySprite, function(entity)
    return meta.new(bt.EnemySprite, {
        _health_bar = bt.HealthBar(0, entity:get_hp_base(), entity:get_hp()),
        _speed_value = bt.SpeedValue(entity:get_speed()),
        _status_consumable_bar = bt.OrderedBox(),
        _name = rt.Label(entity:get_name()),
        _sprite = rt.Sprite(entity:get_sprite_id()),

        _health_visible = true,
        _speed_visible = true,

        _selection_frame = rt.Frame(),
        _selection_state = rt.SelectionState.INACTIVE,

        _snapshot = rt.RenderTexture(1, 1),
        _snapshot_position_x = 0,
        _snapshot_position_y = 0,

        _stunned_animation = bt.StunnedParticleAnimation()
    })
end)

--- @brief
function bt.EnemySprite:realize()
    if self:already_realized() then return end

    self._health_bar:realize()
    self._speed_value:realize()
    self._status_consumable_bar:realize()
    self._name:realize()
    self._sprite:realize()
    self._selection_frame:realize()
    self._stunned_animation:realize()
end

--- @brief
function bt.EnemySprite:size_allocate(x, y, width, height)
    local sprite_w, sprite_h = self._sprite:measure()
    local label_w, label_h = self._name:measure()
    local m = rt.settings.margin_unit
    local current_y = y + height

    current_y = current_y - label_h
    self._status_consumable_bar:fit_into(x + m, current_y, width - 2 * m, label_h)

    current_y = current_y - label_h
    self._health_bar:fit_into(x + m, current_y, width - 2 * m, label_h)

    local speed_w, speed_h = self._speed_value:measure()
    self._speed_value:fit_into(
        x + 0.5 * width - 0.5 * sprite_w + sprite_w - speed_w,
        current_y - speed_h
    )

    current_y = current_y - sprite_h
    self._sprite:fit_into(
        0, 0,
        sprite_w,
        sprite_h
    )
    self._snapshot_position_x = x + 0.5 * width - 0.5 * sprite_w
    self._snapshot_position_y = current_y

    self._selection_frame:fit_into(
        x + 0.5 * width - 0.5 * sprite_w,
        current_y,
        sprite_w,
        sprite_h
    )

    local current_w, current_h = self._snapshot:get_size()
    if current_w ~= sprite_w or current_h ~= sprite_h then
        self._snapshot = rt.RenderTexture(sprite_w, sprite_h)
        self._snapshot:bind()
        self._sprite:draw()
        self._snapshot:unbind()
    end

    local stunned_animation_w = sprite_w
    local stunned_animation_h = sprite_w * rt.settings.battle.enemy_sprite.stunned_animation_width_to_height_ratio
    self._stunned_animation:fit_into(
        self._snapshot_position_x,
        self._snapshot_position_y - 0.5 * stunned_animation_h,
        sprite_w,
        stunned_animation_h
    )
end

--- @override
function bt.EnemySprite:draw()
    self._status_consumable_bar:draw()

    if self._selection_state == rt.SelectionState.ACTIVE then
        self._selection_frame:draw()
    end

    if self._is_visible then
        self:draw_snapshot()
    end

    if self._health_visible then
        self._health_bar:draw()
    end

    if self._speed_visible then
        self._speed_value:draw()
    end

    if self._is_stunned then
        self._stunned_animation:draw()
    end

    self._name:draw()
end

--- @override
function bt.EnemySprite:update(delta)
    self._health_bar:update(delta)
    self._speed_value:update(delta)
    self._status_consumable_bar:update(delta)

    if self._is_stunned then
        self._stunned_animation:update(delta)
    end

    local before = self._sprite:get_frame()
    self._sprite:update(delta)
    if self._sprite:get_frame() ~= before then
        self._snapshot:bind()
        self._sprite:draw()
        self._snapshot:unbind()
    end
end

--- @override
function bt.EnemySprite:measure()
    local label_w, label_h = self._name:measure()
    local sprite_w, sprite_h = self._sprite:measure()
    return sprite_w, 2 * label_h + sprite_h
end

--- @override
function bt.EnemySprite:set_selection_state(state)
    self._selection_state = state
    self._selection_frame:set_selection_state(state)
end

--- @override
function bt.EnemySprite:set_is_stunned(b)
    self._is_stunned = b
end
