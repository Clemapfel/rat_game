--- @class bt.Animation.ALLY_APPEARED
bt.Animation.ALLY_APPEARED = meta.new_type("ALLY_APPEARED", rt.Animation, function(scene, entity)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)
    local duration = rt.settings.battle.animation.enemy_appeared.duration
    return meta.new(bt.Animation.ALLY_APPEARED, {
        _scene = scene,
        _entity = entity,
        _target = nil, -- bt.EntitySprite

        _path = nil, -- rt.Path
        _position_x = 0,
        _position_y = 0,
        _snapshot = rt.RenderTexture(),

        _position_animation = rt.TimedAnimation(duration, 0, 1,
            rt.InterpolationFunctions.CUBE_EASE_OUT, 2
        ),

        _opacity_animation = rt.TimedAnimation(duration / 5, 0, 1,
            rt.InterpolationFunctions.GAUSSIAN_HIGHPASS
        ),

        _black_animation = rt.TimedAnimation(0.1, 0, 1,
            rt.InterpolationFunctions.LINEAR
        )
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

    local target_x, target_y = x, y -- positions, not offsets
    local screen_w, screen_h = love.graphics.getWidth(), love.graphics.getHeight()
    self._path = rt.Path(
        target_x, y + h,
        target_x, target_y
    )

    self._target:set_is_visible(true)
    self._snapshot = rt.RenderTexture(w, h)

    love.graphics.push()
    self._snapshot:bind()
    love.graphics.origin()
    love.graphics.translate(-x, -y)
    self._target:draw()
    self._snapshot:unbind()
    love.graphics.pop()

    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.ALLY_APPEARED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.ALLY_APPEARED:update(delta)
    self._position_animation:update(delta)
    self._opacity_animation:update(delta)
    if self._position_animation:get_is_done() and self._opacity_animation:get_is_done() then
        self._black_animation:update(delta)
    end

    self._position_x, self._position_y = self._path:at(self._position_animation:get_value())

    return self._position_animation:get_is_done() and
        self._opacity_animation:get_is_done() and
        self._black_animation:get_is_done()
end

--- @override
function bt.Animation.ALLY_APPEARED:draw()
    love.graphics.push()
    self._shader:bind()
    self._shader:send("weight", self._black_animation:get_value())
    self._shader:send("alpha", self._opacity_animation:get_value())
    love.graphics.translate(self._position_x, self._position_y)
    self._snapshot:draw()
    self._shader:unbind()
    love.graphics.pop()
end