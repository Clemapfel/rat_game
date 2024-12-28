--- @class bt.Animation.ALLY_APPEARED
bt.Animation.ALLY_APPEARED = meta.new_type("ALLY_APPEARED", rt.Animation, function(scene, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)
    if message ~= nil then meta.assert_string(message) end
    local duration = rt.settings.battle.animation.enemy_appeared.duration
    return meta.new(bt.Animation.ALLY_APPEARED, {
        _scene = scene,
        _entity = entity,
        _target = nil, -- bt.EntitySprite

        _path = nil, -- rt.Path
        _position_x = 0,
        _position_y = 0,
        _snapshot = rt.RenderTexture(),
        _black_weight = 1,

        _position_animation = rt.TimedAnimation(duration, 0, 1,
            rt.InterpolationFunctions.CUBE_EASE_OUT, 2
        ),

        _black_animation = rt.TimedAnimation(duration - 0.1, 0, 1,
            rt.InterpolationFunctions.GAUSSIAN_HIGHPASS
        ),

        _message = message,
        _message_done = false,
        _message_id = nil,
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
function bt.Animation.ALLY_APPEARED:start()
    self._target = self._scene:get_sprite(self._entity)

    local x, y = self._target:get_position()
    local w, h = self._target:measure()

    self._snapshot = rt.RenderTexture(w, h)
    self._target:set_is_visible(true)

    love.graphics.push()
    self._snapshot:bind()
    love.graphics.translate(-x, -y)
    self._target:draw()
    self._snapshot:unbind()
    love.graphics.pop()

    self._path = rt.Path(
        x, y + h,
        x, y
    )

    self._target:set_is_visible(false)

    self._message_id = self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.ALLY_APPEARED:finish()
    self._target:set_is_visible(true)
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.ALLY_APPEARED:update(delta)
    self._position_animation:update(delta)
    self._black_animation:update(delta)

    self._position_x, self._position_y = self._path:at(self._position_animation:get_value())
    return self._position_animation:get_is_done() and
        self._black_animation:get_is_done() and
        self._message_done
end

--- @override
function bt.Animation.ALLY_APPEARED:draw()
    love.graphics.push()
    self._shader:bind()
    self._shader:send("weight", self._black_animation:get_value())
    self._shader:send("alpha", 1) --self._opacity_animation:get_value())
    love.graphics.translate(self._position_x, self._position_y)
    self._snapshot:draw()
    self._shader:unbind()
    love.graphics.pop()
end