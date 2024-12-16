rt.settings.battle.animation.global_status_gained = {
    duration = 4,
    hold_duration = 2,
    density = 10e-5 -- per pixel
}

--- @class bt.Animation
bt.Animation.GLOBAL_STATUS_GAINED = meta.new_type("GLOBAL_STATUS_GAINED", rt.Animation, function(scene, status)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.GlobalStatusConfig)
    return meta.new(bt.Animation.GLOBAL_STATUS_GAINED, {
        _scene = scene,
        _status = status,
        _sprite = rt.Sprite(status:get_sprite_id()),
        _sprite_texture = rt.RenderTexture(),
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _instance_shader = rt.Shader("battle/animations/global_status_gained.glsl"),
        _n_instances = 1,
        _screen_aabb = { 0, 0, 1, 1 },

        _opacity_animation = rt.TimedAnimation(rt.settings.battle.animation.global_status_gained.duration,
            0, 1, rt.InterpolationFunctions.GAUSSIAN_LOWPASS
        ),
        _elapsed = 0,
        _duration = rt.settings.battle.animation.global_status_gained.duration
    })
end)

--- @override
function bt.Animation.GLOBAL_STATUS_GAINED:start()
    local x, y, w, h = rt.aabb_unpack(self._scene:get_bounds())
    self._screen_aabb = { x, y, w, h }

    self._sprite:realize()
    self._sprite:fit_into(0, 0)
    local sprite_w, sprite_h = self._sprite:measure()
    if self._sprite_texture:get_width() ~= sprite_w or self._sprite_texture:get_height() ~= sprite_h then
        self._sprite_texture = rt.RenderTexture(sprite_w, sprite_h)
    end

    self._n_instances = rt.settings.battle.animation.global_status_gained.density * w * h

    love.graphics.push()
    love.graphics.origin()
    self._sprite_texture:bind()
    self._sprite:draw()
    self._sprite_texture:unbind()
    love.graphics.pop()

    local shape_x, shape_y, shape_w, shape_h = -0.5 * sprite_w, -0.5 * sprite_h, self._sprite:get_resolution()
    self._shape:reformat(
        shape_x, shape_y,
        shape_x + shape_w, shape_y,
        shape_x + shape_w, shape_y + shape_h,
        shape_x, shape_y + shape_h
    )
    self._shape:set_texture(self._sprite_texture)
end

--- @override
function bt.Animation.GLOBAL_STATUS_GAINED:finish()

end

--- @override
function bt.Animation.GLOBAL_STATUS_GAINED:update(delta)
    self._elapsed = self._elapsed + delta
    if self._elapsed > rt.settings.battle.animation.global_status_gained.hold_duration then
        self._opacity_animation:update(delta)
        self._shape:set_opacity(self._opacity_animation:get_value())
    end
    return self._opacity_animation:get_is_done()
end

--- @override
function bt.Animation.GLOBAL_STATUS_GAINED:draw()
    self._instance_shader:bind()
    self._instance_shader:send("elapsed", self._elapsed)
    self._instance_shader:send("duration", self._duration)
    self._shape:draw_instanced(self._n_instances)
    self._instance_shader:unbind()

    self._shape:draw()
end