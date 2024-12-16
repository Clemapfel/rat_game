--- @class bt.EnemySprite
bt.EnemySprite = meta.new_type("EnemySprite", bt.EntitySprite, function(entity)
    return meta.new(bt.EnemySprite, {
        _sprite_id = entity:get_config():get_sprite_id(),
        _frame = rt.Frame()
    })
end)

--- @override
function bt.EnemySprite:realize()
    if self:already_realized() then return end
    self:_realize_super(self._sprite_id)

    self._frame:realize()
    self._frame:set_base_color(rt.RGBA(0, 0, 0, 0))
end

--- @override
function bt.EnemySprite:size_allocate(x, y, width, height)
    local sprite_w, sprite_h = self._sprite:measure()
    local m = rt.settings.margin_unit
    local current_y = y + height

    local bar_h = rt.settings.battle.entity_sprite.bar_height

    current_y = current_y - bar_h
    self._status_consumable_bar:fit_into(x + m, current_y, width - 2 * m, bar_h)

    current_y = current_y - bar_h
    self._health_bar:fit_into(x + m, current_y, width - 2 * m, bar_h)

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

    self._frame:fit_into(
        x + 0.5 * width - 0.5 * sprite_w,
        current_y,
        sprite_w,
        sprite_h
    )

    self._snapshot = rt.RenderTexture(sprite_w, sprite_h)
    self._snapshot:bind()
    love.graphics.clear()
    self._sprite:draw()
    self._snapshot:unbind()

    local stunned_animation_w = sprite_w
    local stunned_animation_h = sprite_w * rt.settings.battle.stunned_particle_animation.height_to_width
    self._stunned_animation:fit_into(
        self._snapshot_position_x,
        self._snapshot_position_y - 0.5 * stunned_animation_h,
        sprite_w,
        stunned_animation_h
    )
end

--- @override
function bt.EnemySprite:draw()
    if self._snapshot_visible then
        self:draw_snapshot()
    end

    if self._ui_visible then
        for widget in range(
            self._health_bar,
            self._speed_value,
            self._status_consumable_bar
        ) do
            widget:draw()
        end
    end

    if self._selection_state == rt.SelectionState.ACTIVE then
        self._frame:draw()
    end

    self:draw_bounds()
end

--- @override
function bt.EnemySprite:update(delta)
    self:_update_super(delta)
end

--- @override
function bt.EnemySprite:measure()
    local w, h = self._sprite:measure()
    h = h + select(2, self._health_bar:measure()) + select(2, self._status_consumable_bar:measure())
    return w, h
end
