rt.settings.battle.speed_value = {
    font = rt.Font(25, "assets/fonts/pixel.ttf"),
    tick_speed = 1, -- ticks per second
    tick_acceleration = 10, -- modifies how much distance should affect tick speed, more distance = higher speed factor
}

--- @class bt.SpeedValue
bt.SpeedValue = meta.new_type("SpeedValue", rt.Widget, rt.Animation, function(entity)
    local out = meta.new(bt.SpeedValue, {
        _entity = entity,
        _is_realized = false,
        _elapsed = 1,   -- sic, makes it so `update` is invoked immediately
        _speed_value = -1,
        _speed_target = -1,
        _speed_label = {}  -- rt.Glyph
    })
    return out
end)

--- @brief [internal]
function bt.SpeedValue:_format_value()
    local value = self._speed_value

    --[[
    local priority = self._priority_value
    local priority_string = ""
    if priority < 0 then 
        priority_string = string.rep("-", math.abs(priority))
    elseif priority > 0 then 
        priority_string = string.rep("+", math.abs.priority)
    end
    ]]
    
    return tostring(value)--, priority_string
end

--- @override
function bt.SpeedValue:realize()
    if self._is_realized then return end

    local settings = {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    }

    local speed_string, priority_string = self:_format_value()
    self._speed_label = rt.Glyph(rt.settings.battle.speed_value.font, speed_string, settings)
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
function bt.SpeedValue:measure()
    return self._speed_label:get_size()
end

--- @override
function bt.SpeedValue:update(delta)
    if self._is_realized then
        self._elapsed = self._elapsed + delta

        local diff = (self._speed_value - self._speed_target)
        local speed = (1 + rt.settings.battle.speed_value.tick_acceleration * (math.abs(diff) / 10))

        local tick_duration = 1 / (rt.settings.battle.speed_value.tick_speed * speed)
        if self._elapsed > tick_duration then
            local offset = math.modf(self._elapsed, self._tick_duration)
            if diff > 0 then
                self._speed_value = self._speed_value - offset
            elseif diff < 0 then
                self._speed_value = self._speed_value + offset
            end
            self._elapsed = self._elapsed - offset * tick_duration

            if diff ~= 0 then
                self._speed_label:set_text(self:_format_value())
            end
        end
    end
end

--- @override
function bt.SpeedValue:draw()
    if self._is_realized then
        self._speed_label:draw()
    end
end

--- @override
function bt.SpeedValue:sync()
    self._speed_target = self._entity:get_speed()

    if self._is_realized then
        self._speed_label:set_text(self:_format_value(self._speed_value))
    end
end

--- @brief
function bt.SpeedValue:set_value(value)
    self._speed_target = value
end
