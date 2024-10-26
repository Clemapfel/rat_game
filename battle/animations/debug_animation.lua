--- @brief
function bt.Animation._create_debug_animation(animation_id)
    local out = meta.new_type(animation_id, rt.Animation)
    local label = rt.Label("<o><b>" .. animation_id .. "</o></b>", rt.settings.font.default_large)
    label:realize()
    label:fit_into(0, 0, label:measure())

    getmetatable(out).__call = function(self, scene, ...)
        local targets = {}
        local n_args = select("#", ...)
        for i = 1, n_args do
            local arg = select(i, ...)
            if meta.isa(arg, bt.EntitySprite) then
                table.insert(targets, arg)
            end
        end

        return meta.new(out, {
            _scene = scene,
            _targets = targets,
            _label_positions = {},
            _label = label,
            _label_w = 1,
            _label_h = 1,
            _angle = 0,
            _angle_animation = rt.TimedAnimation(
                1, 0, math.pi * 2,
                rt.InterpolationFunctions.SINE_WAVE
            ),
            _opacity_animation = rt.TimedAnimation(
                1, 0, 1,
                rt.InterpolationFunctions.BUTTERWORTH_BANDPASS, 5
            ),
        })
    end

    out.start = function(self)
        self._label_w, self._label_h = self._label:measure()
        self._label:set_opacity(0)

        self._centers = {}
        for target in values(self._targets) do
            local x, y = target:get_position()
            local w, h = target:measure()
            table.insert(self._label_positions, {
                x + 0.5 * w - 0.5 * self._label_w,
                y + 0.5 * h - 0.5 * self._label_h
            })
        end
    end

    out.update = function(self, delta)
        self._angle_animation:update(delta)
        self._opacity_animation:update(delta)

        self._angle = self._angle_animation:get_value()
        self._label:set_opacity(self._opacity_animation:get_value())

        return self._angle_animation:get_is_done() and self._opacity_animation:get_is_done()
    end

    out.draw = function(self)
        for xy in values(self._label_positions) do
            local x, y = table.unpack(xy)
            love.graphics.push()
            love.graphics.translate(x, y)
            rt.graphics.translate(0.5 * self._label_w, 0.5 * self._label_h)
            rt.graphics.rotate(self._angle)
            rt.graphics.translate(-0.5 * self._label_w, -0.5 * self._label_h)
            self._label:draw()
            love.graphics.pop()
        end

    end

    return out
end