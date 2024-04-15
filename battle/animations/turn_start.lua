rt.settings.battle.animations.turn_start = {
    duration = 2
}

--- @class bt.Animation.TURN_START
bt.Animation.TURN_START = meta.new_type("TURN_START", bt.Animation, function(scene)
    return meta.new(bt.Animation.TURN_START, {
        _scene = scene,

        _label = {},          -- rt.Glyph
        _tunnel_top = {}, -- rt.LogGradient
        _tunnel_bottom = {}, -- rt.LogGradient
        _tunnel_center = {}, -- rt.Rectangle

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
    })
end)

--- @override
function bt.Animation.TURN_START:start()
    self._label = rt.Label("<o><b>TURN START</o></b>", rt.settings.font.default_large, rt.settings.font.default_mono_large)
    self._label:realize()
    self._label_path = {}

    local w, h = rt.graphics.get_width(), rt.graphics.get_height()
    local x, y = 0, 0.5 * h
    local tunnel_height = 0.25 * h

    local r, g, b, a = 0, 0, 0, 0.75
    self._tunnel_top = rt.LogGradient(rt.RGBA(r, g, b, a), rt.RGBA(r, g, b, 0))
    self._tunnel_bottom = rt.LogGradient(rt.RGBA(r, g, b, 0), rt.RGBA(r, g, b, a))
    self._tunnel_center = rt.Rectangle(0, 0, 1, 1)

    for tunnel in range(self._tunnel_bottom, self._tunnel_top) do
        tunnel:set_is_vertical(true)
    end
    self._tunnel_center:set_color(rt.RGBA(r, g, b, a))

    local tunnel_h = 0.25 * rt.graphics.get_height()
    local gradient_h = 0.2 * tunnel_h
    self._tunnel_center:resize(x, y - 0.5 * tunnel_h, w, tunnel_h)
    self._tunnel_top:resize(x, y - 0.5 * tunnel_height - gradient_h, w, gradient_h)
    self._tunnel_bottom:resize(x, y + 0.5 * tunnel_h, w, gradient_h)
end

--- @override
function bt.Animation.TURN_START:update(delta)
    if not self._is_started then return end

    local duration = rt.settings.battle.animations.turn_start.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    local hold_duration = 0.5
    local function label_pos(x)
        local left_hold = 0.5 - hold_duration / 2
        local right_hold = 0.5 + hold_duration / 2
        if x < left_hold then
            return 0.5 * (x / left_hold)
        elseif x >= left_hold and x <= right_hold then
            return 0.5
        else
            return (0.5 / (1 - right_hold)) * x + 0.5 - (0.5 * right_hold) / (1 - right_hold)
        end
    end

    -- label animation
    local label_w, label_h = self._label:measure()
    local pos_x = label_pos(fraction)

    self._label:fit_into(
        pos_x * rt.graphics.get_width() - 0.5 * label_w,
        0.5 * rt.graphics.get_height() - 0.5 * label_h,
        label_w, label_h
    )

    -- tunnel fade
    local fade_duration = 0.2
    local function tunnel_alpha(x)
        local order = 2
        if x < fade_duration then
            return rt.butterworth_highpass(x / fade_duration, order)
        elseif x > 1 - fade_duration then
            return rt.butterworth_lowpass((1 - x) / fade_duration, order)
        else
            return 1
        end
    end

    self._tunnel_top:set_opacity(tunnel_alpha(fraction))
    self._tunnel_bottom:set_opacity(tunnel_alpha(fraction))
    self._tunnel_center:set_opacity(tunnel_alpha(fraction))

    return self._elapsed < duration
end

--- @override
function bt.Animation.TURN_START:finish()
end

--- @override
function bt.Animation.TURN_START:draw()
    love.graphics.setCanvas(nil)

    self._tunnel_top:draw()
    self._tunnel_bottom:draw()
    self._tunnel_center:draw()

    self._label:draw()
end
