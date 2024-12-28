rt.settings.battle.animation.enemy_appeared = {
    duration = 2
}

--- @class bt.Animation.ENEMY_APPEARED
bt.Animation.ENEMY_APPEARED = meta.new_type("ENEMY_APPEARED", rt.Animation, function(scene, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)
    local duration = rt.settings.battle.animation.enemy_appeared.duration
    return meta.new(bt.Animation.ENEMY_APPEARED, {
        _scene = scene,
        _entity = entity,
        _target = nil,

        _path = nil, -- rt.Path
        _position_x = 0,
        _position_y = 0,
        _position_animation = rt.TimedAnimation(duration, 0, 1,
            rt.InterpolationFunctions.CUBE_EASE_OUT
        ),

        _opacity_animation = rt.TimedAnimation(duration / 5, 0, 1,
            rt.InterpolationFunctions.GAUSSIAN_HIGHPASS
        ),

        _black_animation = rt.TimedAnimation(0.1, 0, 1,
            rt.InterpolationFunctions.LINEAR
        ),

        _message = message,
        _message_done = false,
        _message_id = nil
    })
end, {
    _shader = (function()
        local out = rt.Shader("battle/animations/entity_appeared.glsl")
        local black = rt.Palette.BLACK
        out:send("black", {black.r, black.g, black.b})
        return out
    end)()
})

--- @override
function bt.Animation.ENEMY_APPEARED:start()
    self._target = self._scene:get_sprite(self._entity)

    self._target:set_is_visible(false)
    self._target:set_animation_active(false)

    local x, y = self._target:get_position()
    local w, h = self._target:measure()

    local target_x, target_y = 0, 0 -- offsets, not position
    local screen_w, screen_h = love.graphics.getWidth(), love.graphics.getHeight()
    self._path = rt.Path(
        target_x - 0.5 * screen_w - w, target_y,
        target_x, target_y
    )

    self._message_id = self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.ENEMY_APPEARED:finish()
    self._target:set_is_visible(true)
    self._target:set_animation_active(true)
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.ENEMY_APPEARED:update(delta)
    self._position_animation:update(delta)
    self._opacity_animation:update(delta)
    if self._position_animation:get_is_done() and self._opacity_animation:get_is_done() then
        self._black_animation:update(delta)
    end

    self._position_x, self._position_y = self._path:at(self._position_animation:get_value())

    return self._position_animation:get_is_done() and
        self._opacity_animation:get_is_done() and
        self._black_animation:get_is_done() and
        self._message_done
end

--- @override
function bt.Animation.ENEMY_APPEARED:draw()
    self._shader:bind()
    self._shader:send("weight", self._black_animation:get_value())
    self._shader:send("alpha", self._opacity_animation:get_value())
    love.graphics.translate(self._position_x, self._position_y)
    self._target:draw_snapshot()
    love.graphics.translate(-self._position_x, -self._position_y)
    self._shader:unbind()
end