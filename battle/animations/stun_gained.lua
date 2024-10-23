--- @class bt.Animation.STUN_GAINED
--- @param scene bt.BattleScene
--- @param sprite bt.EntitySprite
bt.Animation.STUN_GAINED = meta.new_type("STUN_GAINED", rt.Animation, function(scene, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(sprite, bt.EntitySprite)
    return meta.new(bt.Animation.STUN_GAINED, {
        _scene = scene,
        _target = sprite,

        _snapshot = nil, -- rt.RenderTexture
        _offset_x = 0,
        _offset_y = 0,
        _timer = nil, -- rt.TimedAnimation
    })
end, {
    _path = nil,
    _duration = 1, -- seconds
    _n_shakes = 2
})

--- @overload
function bt.Animation.STUN_GAINED:start()
    if self._path == nil then
        local bounds = self._scene:get_bounds()
        local magnitude = rt.settings.margin_unit * 3
        local n_shakes = self._n_shakes
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
        self._path = rt.Spline(vertices)
    end

    self._timer = rt.TimedAnimation(
        self._duration, 0, 1,
        rt.InterpolationFunctions.GAUSSIAN_BANDPASS
    )

    self._target:set_is_visible(false)
end

--- @overload
function bt.Animation.STUN_GAINED:update(delta)
    self._offset_x, self._offset_y = self._path:at(self._timer:get_value())
    self._timer:update(delta)
    return self._timer:get_is_done()
end

--- @overload
function bt.Animation.STUN_GAINED:draw()
    self._target:draw_snapshot(self._offset_x, self._offset_y)
end

--- @overload
function bt.Animation.STUN_GAINED:finish()
    self._target:set_is_visible(true)
    self._target:set_is_stunned(true)
end