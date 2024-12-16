--- @class bt.Animation.ENEMY_KNOCKED_OUT
bt.Animation.ENEMY_KNOCKED_OUT = meta.new_type("ENEMY_KNOCKED_OUT", rt.Animation, function(scene, entity)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)

    local fade_in = 0.1
    local hold = 2
    local fade_out = 0.3
    local total = fade_in + hold + fade_out
    return meta.new(bt.Animation.ENEMY_KNOCKED_OUT, {
        _scene = scene,
        _entity = entity,
        _target = nil,

        _fade_in_animation = rt.TimedAnimation(fade_in, 0, 1, rt.InterpolationFunctions.LINEAR),
        _fade_in_shape = nil, -- rt.VertexRectangle
        _hold_animation = rt.TimedAnimation(hold),
        _fade_out_animation = rt.TimedAnimation(fade_out, 0, 1, rt.InterpolationFunctions.GAUSSIAN_LOWPASS),

        _vignette_value = rt.TimedAnimation(total, 0, 0.65, rt.InterpolationFunctions.SHELF, 100),
        _vignette_shader = rt.Shader("battle/animations/enemy_knocked_out.glsl"),

        _knockback_path = nil, -- rt.Path
        _knockback_position_animation = rt.TimedAnimation(total, 0, 1, rt.InterpolationFunctions.LINEAR),
        _sprite_x = 0,
        _sprite_y = 0,

        _knock_out_sprite_set = false,
        _elapsed = 0
    })
end)

--- @override
function bt.Animation.ENEMY_KNOCKED_OUT:start()
    self._target = self._scene:get_sprite(self._entity)

    self._fade_in_shape = rt.VertexRectangle(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    self._fade_in_shape:set_opacity(0)
    self._vignette_shader:send("value", 0)
    self._target:set_is_visible(false)

    local x, y = self._target:get_position()
    local w, h = self._target:measure()
    self._vignette_shader:send("position", {x + 0.5 * w, y + 0.5 * h})

    local m = rt.settings.margin_unit
    local end_x, end_y = rt.translate_point_by_angle(0, 0, 5 * m, math.rad(-45))
    self._knockback_path = rt.Path({
        0, 0,
        end_x, end_y
    })
end

--- @override
function bt.Animation.ENEMY_KNOCKED_OUT:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.ENEMY_KNOCKED_OUT:update(delta)
    self._elapsed = self._elapsed + delta

    self._vignette_value:update(delta)
    self._knockback_position_animation:update(delta)
    if self._fade_in_animation:update(delta) then
        if self._hold_animation:update(delta) then
            self._fade_out_animation:update(delta)
        end

        if self._knock_out_sprite_set == false then
            self._target:set_state(bt.EntityState.KNOCKED_OUT)
            self._knock_out_sprite_set = true
        end
    end

    local fraction = self._fade_in_animation:get_value()
    if self._fade_in_animation:get_is_done() then
        fraction = self._fade_out_animation:get_value()
    end
    self._vignette_shader:send("value", self._vignette_value:get_value())

    self._fade_in_shape:set_color(rt.color_mix(
        rt.RGBA(1, 1, 1, 1),
        rt.Palette.RED_2,
        fraction
    ))
    self._fade_in_shape:set_opacity(fraction)

    return self._fade_in_animation:get_is_done() and
        self._hold_animation:get_is_done() and
        self._fade_out_animation:get_is_done() and
        self._knockback_position_animation:get_is_done()
end

--- @override
function bt.Animation.ENEMY_KNOCKED_OUT:draw()
    self._vignette_shader:bind()
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
    self._fade_in_shape:draw()
    rt.graphics.set_blend_mode()
    self._vignette_shader:unbind()

    love.graphics.push()
    love.graphics.translate(self._sprite_x, self._sprite_y)
    self._target:draw_snapshot()
    love.graphics.pop()
end