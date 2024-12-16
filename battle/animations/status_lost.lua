rt.settings.battle.animation.status_lost = {
    duration = 1,
    hold_duration = 1
}

--- @class bt.Animation.STATUS_LOST
bt.Animation.STATUS_LOST = meta.new_type("STATUS_LOST", rt.Animation, function(scene, status, entity)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.StatusConfig)
    meta.assert_isa(sprite, bt.Entity)
    return meta.new(bt.Animation.STATUS_LOST, {
        _scene = scene,
        _status = status,
        _entity = entity,
        _target = nil, -- bt.EntitySprite
        _sprite = rt.Sprite(status:get_sprite_id()),
        _sprite_texture = rt.RenderTexture(),
        _batch = nil, -- rt.SpriteBatch
        _shapes = {},
        _step = 1,
        _elapsed = 0,
        _fade_in_animation = rt.TimedAnimation(0.1, 0, 1, rt.InterpolationFunctions.LINEAR),
        _fade_out_animation = rt.TimedAnimation(rt.settings.battle.animation.status_lost.duration,
            0, 1, rt.InterpolationFunctions.GAUSSIAN_LOWPASS
        ),
        _opacity = 0
    })
end)

--- @override
function bt.Animation.STATUS_LOST:start()
    self._target = self._scene:get_sprite(self._entity)
    self._sprite:realize()
    local sprite_w, sprite_h = self._sprite:measure()

    self._sprite_texture = rt.RenderTexture(sprite_w, sprite_h)
    love.graphics.push()
    love.graphics.origin()
    self._sprite_texture:bind()
    self._sprite:draw()
    self._sprite_texture:unbind()
    love.graphics.pop()

    self._shapes = {}
    local step = 15
    local n_cols, n_rows = self._sprite_texture:get_width() / step, self._sprite_texture:get_height() / step
    n_cols = math.ceil(n_cols)
    n_rows = math.ceil(n_rows)

    self._batch = rt.SpriteBatch(self._sprite_texture, n_cols * n_rows)

    local total_w, total_h = n_cols * step, n_rows * step
    local target_x, target_y, target_w, target_h = rt.aabb_unpack(self._target:get_bounds())

    local start_x, start_y = target_x + 0.5 * target_w - 0.5 * total_w, target_y + 0.5 * target_h - 0.5 * total_h
    local center_x, center_y = start_x + 0.5 * total_w, start_y + 0.5 * total_h

    local x, y = start_x, start_y
    for row_i = 1, n_rows do
        for col_i = 1, n_cols do

            local texture_x, texture_y = (x - start_x) / total_w, (y - start_y) / total_h
            local texture_w, texture_h = step / total_w, step / total_h

            local shape = {}
            shape.id = self._batch:add(
                x, y, step, step,
                texture_x, texture_y,
                texture_w, texture_h
            )

            shape.current_x = 0
            shape.current_y = 0
            shape.centroid_x = x + 0.5 * step
            shape.centroid_y = y + 0.5 * step
            shape.rotation = 0

            shape.last_x, shape.last_y = rt.translate_point_by_angle(
                shape.current_x, shape.current_y, -0.5,
                rt.angle( shape.centroid_x - center_x,  shape.centroid_y - center_y) + (2 * math.pi) / 6
            )

            table.insert(self._shapes, shape)
            x = x + step
        end
        y = y + step
        x = start_x
    end
end

--- @override
function bt.Animation.STATUS_LOST:update(delta)
    self._elapsed = self._elapsed + delta

    if self._elapsed > rt.settings.battle.animation.status_lost.hold_duration then
        local acceleration = self._elapsed + 1
        for shape in values(self._shapes) do
            local current_x, current_y = shape.current_x, shape.current_y

            local next_x = shape.current_x + (shape.current_x - shape.last_x) + acceleration * delta * delta
            local next_y = shape.current_y + (shape.current_y - shape.last_y) + acceleration * delta * delta
            shape.current_x, shape.current_y = next_x, next_y
            shape.last_x, shape.last_y = current_x, current_y
            self._batch:set_offset(shape.id, shape.current_x, shape.current_y)
        end

        self._fade_out_animation:update(delta)
        self._opacity = self._fade_out_animation:get_value()
    else
        self._fade_in_animation:update(delta)
        self._opacity = self._fade_in_animation:get_value()
    end

    return self._fade_out_animation:get_is_done()
end

--- @override
function bt.Animation.STATUS_LOST:draw()
    love.graphics.setColor(1, 0, 1, 1)
    self._batch:draw()
end
