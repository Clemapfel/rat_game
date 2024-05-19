rt.settings.battle.speed_value = {
    font = rt.settings.font.default_mono,--rt.Font(25, "assets/fonts/pixel.ttf"),
    tick_speed = 1, -- ticks per second
    tick_acceleration = 10, -- modifies how much distance should affect tick speed, more distance = higher speed factor
}

--- @class bt.SpeedValue
bt.SpeedValue = meta.new_type("SpeedValue", rt.Widget, rt.Animation, function()
    return meta.new(bt.SpeedValue, {
        _elapsed = 1,   -- sic, makes it so `update` is invoked immediately
        _speed_current = -1,
        _speed_target = -1,
        _speed_label = {}  -- rt.Glyph
    })
end)

--- @brief [internal]
function bt.SpeedValue:_format_value()
    return tostring(self._speed_current)
end

--- @brief
function bt.SpeedValue:realize()
    if self._is_realized then return end

    local speed_string, priority_string = self:_format_value()
    self._speed_label = rt.Glyph(rt.settings.battle.speed_value.font, speed_string, {
        is_outlined = true,
        is_bold = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    })
    self:set_is_animated(true)
    self:update(0)
    self._is_realized = true
end

--- @override
function bt.SpeedValue:size_allocate(x, y, width, height)
    local label_w, label_h = self._speed_label:get_size()
    self._speed_label:set_position(x + 0.5 * width - 0.5 * label_w, y + 0.5 * height - 0.5 * label_h)
end

--- @override
function bt.SpeedValue:update(delta)
    if self._is_realized == true then
        self._elapsed = self._elapsed + delta
        
        local diff = self._speed_current - self._speed_target
        local speed = 1 + rt.settings.battle.speed_value.tick_acceleration * (math.abs(diff) / 10)

        local tick_duration = 1 / (rt.settings.battle.speed_value.tick_speed * speed)
        if self._elapsed > tick_duration then
            local offset = math.modf(self._elapsed, self._tick_duration)
            if diff > 0 then
                self._speed_current = self._speed_current - offset
            elseif diff < 0 then
                self._speed_current = self._speed_current + offset
            end
            self._elapsed = self._elapsed - offset * tick_duration

            if diff ~= 0 then
                self._speed_label:set_text(self:_format_value())
            end
        end
    end
end

--- @override
function bt.SpeedValue:measure()
    return self._speed_label:get_size()
end

--- @override
function bt.SpeedValue:draw()
    if self._is_realized == true then
        self._speed_label:draw()
    end
end

--- @override
function bt.SpeedValue:set_value(value)
    self._speed_target = value
end

--- @brief
function bt.SpeedValue:synchronize(entity)
    self._speed_current = entity:get_speed()
    self._speed_target = entity:get_speed()
    self._speed_label:set_text(self:_format_value())
end

--- @brief
function bt.SpeedValue:skip()
    self._speed_current = self._speed_target
    self._speed_label:set_text(self:_format_value())
end

--- @brief
function bt.SpeedValue:set_opacity(alpha)
    self._speed_label:set_opacity(alpha)
end