rt.settings.battle.enemy_sprite = {
    sprite_scale = 4
}

--- @class bt.EnemySprite
bt.EnemySprite = meta.new_type("EnemySprite", bt.BattleSprite, function(entity)
    meta.assert_isa(entity, bt.Entity)
    return meta.new(bt.EnemySprite, {
        _entity = entity,
        _sprite = rt.Sprite(entity.sprite_id),

        _health_bar = bt.HealthBar(entity),
        _speed_value = bt.SpeedValue(entity),
        _status_bar = bt.StatusBar(entity),

        _selection_frame = rt.SelectionIndicator()
    })
end)

--- @override
function bt.EnemySprite:realize()
    if self._is_realized then return end
    self._is_realized = true

    local sprite_w, sprite_h = self._sprite:get_resolution()
    local scale = rt.settings.battle.enemy_sprite.sprite_scale
    self._sprite:set_minimum_size(sprite_w * scale, sprite_h * scale)
    self._sprite:realize()

    self._health_bar:realize()
    self._speed_value:realize()
    self._status_bar:realize()

    self._selection_frame:realize()

    for to_animate in range(self, self._health_bar, self._speed_value, self._status_bar, self._sprite) do
        to_animate:set_is_animated(true)
    end

    self:set_is_animated(true)
    self:reformat()
    self:synchronize(self._entity)
end

--- @override
function bt.EnemySprite:update(delta)
    -- noop
end

--- @override
function bt.EnemySprite:size_allocate(x, y, width, height)
    self._sprite:fit_into(x, y, width, height)
    local sprite_x, sprite_y = self._sprite:get_position()
    local sprite_w, sprite_h = self._sprite:measure()

    local m = 0.5 * rt.settings.margin_unit
    local hp_bar_bounds = rt.AABB(sprite_x, sprite_y + sprite_h + m, sprite_w, rt.settings.battle.health_bar.hp_font:get_size() + 2 * m)
    hp_bar_bounds.x = hp_bar_bounds.x + rt.settings.margin_unit
    hp_bar_bounds.width = hp_bar_bounds.width - 2 * rt.settings.margin_unit -- why 2?
    self._health_bar:fit_into(hp_bar_bounds)

    self._status_bar:fit_into(
        sprite_x, hp_bar_bounds.y + hp_bar_bounds.height,
        math.max(sprite_w, hp_bar_bounds.width), hp_bar_bounds.height
    )

    local speed_value_w, speed_value_h = self._speed_value:measure()
    self._speed_value:fit_into(
        sprite_x + sprite_w - speed_value_w * 1.5,
        sprite_y + sprite_h - speed_value_h
    )

    self._selection_frame:resize(self._sprite)
end

--- @override
function bt.EnemySprite:draw()
    if self._is_realized ~= true then return end

    self._sprite:draw()
    bt.BattleSprite.draw(self)

    if self._is_selected then
        self._selection_frame:draw()
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
    self._sprite:set_is_visible(b)
end

--- @override
function bt.EnemySprite:get_is_visible()
    return self._sprite:get_is_visible()
end

--- @brief
function bt.EnemySprite:set_opacity(alpha)
    self._opacity = alpha
    self._sprite:set_opacity(alpha)
    self._health_bar:set_opacity(alpha)
    self._status_bar:set_opacity(alpha)
    self._speed_value:set_opacity(alpha)
end

--- @brief
function bt.EnemySprite:set_state(state)
    self._state = state
    self._health_bar:set_state(state)

    if state == bt.EntityState.KNOCKED_OUT then
        local animation_id = rt.settings.battle.battle_sprite.animation_ids.knocked_out
        if self._sprite:has_animation(animation_id) then
            self._sprite:set_animation(animation_id)
        end
    elseif state == bt.EntityState.DEAD then
        local animation_id = rt.settings.battle.battle_sprite.animation_ids.knocked_out
        if self._sprite:has_animation(animation_id) then
            self._sprite:set_animation(animation_id)
        end
    else
        local animation_id = rt.settings.battle.battle_sprite.animation_ids.idle
        if self._sprite:has_animation(animation_id) then
            self._sprite:set_animation(animation_id)
        end
    end
end

--- @brief
function bt.EnemySprite:measure()
    return self._sprite:measure()
end
