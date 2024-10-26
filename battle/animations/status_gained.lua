rt.settings.battle.animation.status_gained = {
    duration = 1
}

--- @class bt.Animation.STATUS_APPLIED
--- @param status bt.Status
--- @param sprite bt.EntitySprite
bt.Animation.STATUS_GAINED = meta.new_type("STATUS_GAINED", rt.Animation, function(scene, status, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.Status)
    meta.assert_isa(sprite, bt.EntitySprite)

    local duration = rt.settings.battle.animation.status_gained.duration
    local rotation = math.pi / 10
    return meta.new(bt.Animation.STATUS_GAINED, {
        _scene = scene,
        _status = status,
        _target = sprite,
        _sprite = rt.Sprite(status:get_sprite_id()),
        _sprite_x = 0,
        _sprite_y = 0,
        _sprite_angle = 0,

        _rotation_animation = rt.TimedAnimation(duration,
            -2 * rotation, 0,
            rt.InterpolationFunctions.LINEAR
        ),

        _opacity_animation = rt.TimedAnimation(2 * duration, -- hold for 1s after others are done
            0, 1,
            rt.InterpolationFunctions.SHELF, 1, 20
        ),

        _position_animation = rt.TimedAnimation(duration,
            0, 1,
            rt.InterpolationFunctions.LINEAR
        ),
        _sprite_path = nil, -- rt.Spline
    })
end)

--- @brief
function bt.Animation.STATUS_GAINED:start()
    self._sprite:realize()
    local sprite_w, sprite_h = self._sprite:measure()
    self._sprite:fit_into(-0.5 * sprite_w, -0.5 * sprite_h)

    local x, y = self._target:get_position()
    local w, h = self._target:measure()
    local offset = 0.2
    self._sprite_path = rt.Spline({
        x + 0.5 * w, y + (0.5 + offset) * h,
        x + 0.5 * w, y + (0.5 - offset) * h
    })
end

--- @brief
function bt.Animation.STATUS_GAINED:finish()
end

--- @brief
function bt.Animation.STATUS_GAINED:update(delta)
    for animation in range(
        self._rotation_animation,
        self._opacity_animation,
        self._position_animation
    ) do
        animation:update(delta)
    end

    self._sprite_x, self._sprite_y = self._sprite_path:at(self._position_animation:get_value())
    self._sprite:set_opacity(self._opacity_animation:get_value())
    self._sprite_angle = self._rotation_animation:get_value()

    return self._rotation_animation:get_is_done() and
        self._opacity_animation:get_is_done() and
        self._position_animation:get_is_done()
end

--- @brie
function bt.Animation.STATUS_GAINED:draw()
    love.graphics.push()
    love.graphics.translate(self._sprite_x, self._sprite_y)
    love.graphics.scale(2)
    love.graphics.rotate(self._sprite_angle)
    self._sprite:draw()
    love.graphics.pop()
end