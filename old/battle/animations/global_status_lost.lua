rt.settings.battle.animation.global_status_lost = {
    duration = 4,
    hold_duration = 1.5,
    density = 1 / 4000 -- per pixel
}

--- @class bt.Animation
--- @param status bt.GlobalStatusConfig
bt.Animation.GLOBAL_STATUS_LOST = meta.new_type("GLOBAL_STATUS_LOST", rt.Animation, function(scene, status, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(status, bt.GlobalStatusConfig)
    if message ~= nil then meta.assert_string(message) end
    local hold = rt.settings.battle.animation.global_status_lost.hold_duration
    local total = rt.settings.battle.animation.global_status_lost.duration
    local blow = total - hold
    return meta.new(bt.Animation.GLOBAL_STATUS_LOST, {
        _scene = scene,
        _status = status,
        _sprite = rt.Sprite(status:get_sprite_id()),
        _sprite_texture = rt.RenderTexture(),
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _instance_shader = rt.Shader("battle/animations/global_status_lost.glsl"),
        _n_instances = 1,
        _screen_aabb = { 0, 0, 1, 1 },

        _opacity_animation = rt.TimedAnimation(total,
            0, 1, rt.InterpolationFunctions.SHELF, 7
        ),
        _blow_animation = rt.TimedAnimation(blow, 0, 2),
        _hold_animation = rt.TimedAnimation(hold),

        _duration = rt.settings.battle.animation.global_status_lost.duration,
        _message = message,
        _message_done = false,
        _message_id = nil
    })
end)

--- @override
function bt.Animation.GLOBAL_STATUS_LOST:start()
    local x, y, w, h = rt.aabb_unpack(self._scene:get_bounds())
    self._screen_aabb = { x, y, w, h }

    self._sprite:realize()
    self._sprite:fit_into(0, 0)
    local sprite_w, sprite_h = self._sprite:measure()
    if self._sprite_texture:get_width() ~= sprite_w or self._sprite_texture:get_height() ~= sprite_h then
        self._sprite_texture = rt.RenderTexture(sprite_w, sprite_h)
    end

    self._n_instances = rt.settings.battle.animation.global_status_lost.density * w * h

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

    self._message_id = self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.GLOBAL_STATUS_LOST:finish()
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.GLOBAL_STATUS_LOST:update(delta)
    -- hold, then start blow away animation
    self._opacity_animation:update(delta)
    if self._hold_animation:update(delta) then
        self._blow_animation:update(delta)
    end

    self._shape:set_opacity(self._opacity_animation:get_value())
    return self._opacity_animation:get_is_done()
        and self._hold_animation:get_is_done()
        and self._blow_animation:get_is_done()
        and self._message_done
end

--- @override
function bt.Animation.GLOBAL_STATUS_LOST:draw()
    self._instance_shader:bind()
    self._instance_shader:send("elapsed", self._blow_animation:get_value())
    self._instance_shader:send("duration", self._duration)
    self._instance_shader:send("n_instances", self._n_instances)
    self._shape:draw_instanced(self._n_instances)
    self._instance_shader:unbind()

    self._shape:draw()
end