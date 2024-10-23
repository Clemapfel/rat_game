--- @class bt.Animation.STUN_GAINED
--- @param scene bt.BattleScene
--- @param sprite bt.EntitySprite
bt.Animation.STUN_GAINED = meta.new_type("STUN_GAINED", rt.Animation, function(scene, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(sprite, bt.EntitySprite)

    return meta.new(bt.Animation.STUN_GAINED, {
        _scene = scene,
        _target = sprite,
    })
end, {
    path = nil,
})

--- @overload
function bt.Animation.STUN_GAINED:start()
    if self.path == nil then
        local bounds = self._scene:get_bounds()
        local magnitude = 0.1 * bounds.width
        local n_shakes = 4
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
        self.path = rt.Spline(vertices)
    end
end

--- @overload
function bt.Animation.STUN_GAINED:update(delta)

end

--- @overload
function bt.Animation.STUN_GAINED:finish()
    self._target:set_is_stunned(true)
end