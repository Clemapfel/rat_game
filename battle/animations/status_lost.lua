rt.settings.battle.animation.status_lost = {
    duration = 1
}

--- @class bt.Animation.STATUS_APPLIED
--- @param status bt.Status
--- @param sprite bt.EntitySprite
bt.Animation.STATUS_LOST = meta.new_type("STATUS_LOST", rt.Animation, function(scene, status, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.Status)
    meta.assert_isa(sprite, bt.EntitySprite)
    local duration = rt.settings.battle.animation.status_lost.duration

    return meta.new(bt.Animation.STATUS_LOST, {
        _scene = scene,
        _status = status,
        _target = sprite,
        _sprite = nil,
        _sprite_x = 0,
        _sprite_y = 0,
        _sprite_scale = 1,
        _sprite_opacity = 0,

        _scale_animation = rt.TimedAnimation(duration,
            1, 4, rt.InterpolationFunctions.LINEAR
        ),
        _opacity_animation = rt.TimedAnimation(duration,
            0, 1, rt.InterpolationFunctions.SKEWED_GAUSSIAN_DECAY
        ),

        _position_path = nil, -- rt.Spline
        _position_animation = rt.TimedAnimation(duration,
            0, 1, rt.InterpolationFunctions.LINEAR
        )
    })
end, {
    status_to_sprite = {}
})

--- @override
function bt.Animation.STATUS_LOST:start()
    local sprite = bt.Animation.STATUS_LOST.status_to_sprite[self._status]
    if sprite == nil then
        sprite = rt.Sprite(self._status:get_sprite_id())
        sprite:realize()
        sprite:set_opacity(0)
        bt.Animation.STATUS_LOST.status_to_sprite[self._status] = sprite
    end
    self._sprite = sprite

    local x, y = self._target:get_position()
    local w, h = self._target:measure()
    self._sprite_x = x + 0.5 * w
    self._sprite_y = y + 0.5 * h
    self._sprite_scale = 1

    self._position_path = rt.Spline({
        x + 0.5 * w, y + 0.5 * h,
        x + 0.5 * w, y
    })

    local sprite_w, sprite_h = self._sprite:measure()
    self._sprite:fit_into(-0.5 * sprite_w, -0.5 * sprite_h)
    self._sprite:set_opacity(0)
end

--- @override
function bt.Animation.STATUS_LOST:finish()
    self._sprite:set_opacity(0)
end

--- @override
function bt.Animation.STATUS_LOST:update(delta)
    for animation in range(
        self._scale_animation,
        self._opacity_animation,
        self._position_animation
    ) do
        animation:update(delta)
    end

    self._sprite_opacity = self._opacity_animation:get_value()
    self._sprite_scale = self._scale_animation:get_value()
    self._sprite_x, self._sprite_y = self._position_path:at(self._position_animation:get_value())
    return self._opacity_animation:get_is_done() and
        self._scale_animation:get_is_done() and
        self._position_animation:get_is_done()
end

--- @override
function bt.Animation.STATUS_LOST:draw()
    self._sprite:set_opacity(self._sprite_opacity) -- in :draw because of caching

    love.graphics.push()
    love.graphics.translate(self._sprite_x, self._sprite_y)
    love.graphics.scale(self._sprite_scale)
    self._sprite:draw()
    love.graphics.pop()
end