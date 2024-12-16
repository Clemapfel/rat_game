--- @class bt.Animation.STUN_GAINED
--- @param scene bt.BattleScene
--- @param sprite bt.EntitySprite
bt.Animation.STUN_GAINED = meta.new_type("STUN_GAINED", rt.Animation, function(scene, entity)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)

    local type = bt.Animation.STUN_GAINED
    if type._initialized == false then
        local bounds = scene:get_bounds()
        local magnitude = rt.settings.margin_unit * 3
        local n_shakes = type._n_shakes
        local vertices = {}
        for i = 1, n_shakes do
            for p in range(
                0, 0,
                -magnitude, 0,
                magnitude, 0,
                0, 0
            ) do
                table.insert(vertices, p)
            end
        end
        type._path = rt.Spline(vertices)

        type._label:realize()
        type._label_w, type._label_h =  type._label:measure()
        type._label:fit_into(0, 0, type._label_w, type._label_h)
        type._initialized = true
    end

    return meta.new(bt.Animation.STUN_GAINED, {
        _scene = scene,
        _entity = entity,
        _target = nil, -- bt.EntitySprite

        _snapshot = nil, -- rt.RenderTexture
        _offset_x = 0,
        _offset_y = 0,
        _label_position_x = 0,
        _label_position_y = 0,
        _sprite_timer = nil, -- rt.TimedAnimation
        _label_timer = nil,
    })
end, {
    _path = nil, -- rt.Spline
    _duration = 1, -- seconds
    _n_shakes = 2,
    _label = rt.Label("<o><b>" .. rt.Translation.battle.stun_gained_label .. "</o></b>"),
    _label_w = 0,
    _label_h = 0,
    _initialized = false
})

--- @overload
function bt.Animation.STUN_GAINED:start()
    self._target = self._scene:get_sprite(self._entity)
    self._sprite_timer = rt.TimedAnimation(
        self._duration, 0, 1,
        rt.InterpolationFunctions.GAUSSIAN
    )

    self._target:set_is_visible(false)

    local bounds = self._target:get_bounds()
    self._label_position_x = bounds.x + 0.5 * bounds.width - 0.5 * self._label_w
    self._label_position_y = bounds.y + 0.5 * bounds.height - 0.5 * self._label_h

    local center_y = bounds.y + bounds.height * 0.5 - self._label_h * 0.5
    self._label_timer = rt.TimedAnimation(
        self._duration,
        center_y + 0.1 * bounds.height,
        center_y * 0.5 - 0.1 * bounds.height,
        rt.InterpolationFunctions.LINEAR
    )

    self._label:set_opacity(0)
end

--- @overload
function bt.Animation.STUN_GAINED:update(delta)
    self._offset_x, self._offset_y = self._path:at(self._sprite_timer:get_value())
    self._sprite_timer:update(delta)
    self._label_timer:update(delta)

    self._label_position_y = self._label_timer:get_value()
    self._label:set_opacity(self._sprite_timer:get_value())
    return self._sprite_timer:get_is_done() and self._label_timer:get_is_done()
end

--- @overload
function bt.Animation.STUN_GAINED:draw()
    self._target:draw_snapshot(self._offset_x, self._offset_y)

    love.graphics.translate(self._label_position_x, self._label_position_y)
    self._label:draw()
    love.graphics.translate(-self._label_position_x, -self._label_position_y)
end

--- @overload
function bt.Animation.STUN_GAINED:finish()
    self._target:set_is_visible(true)
    self._target:set_is_stunned(true)
end