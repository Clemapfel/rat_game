rt.settings.battle.health_bar = {
    hp_font = rt.settings.font.default_mono_small,

    hp_color_100 = rt.Palette.LIGHT_GREEN_2,
    hp_color_75 = rt.Palette.GREEN_1,
    hp_color_50 = rt.Palette.YELLOW_2,
    hp_color_25 = rt.Palette.YELLOW_2,
    hp_color_10 = rt.Palette.YELLOW_2,
    hp_color_0 = rt.Palette.YELLOW_2,

    hp_background_color = rt.Palette.GREEN_3,
    corner_radius = 7,
    tick_speed = 10, -- ticks per second
    tick_acceleration = 10, -- modifies how much distance should affect tick speed, more distance = higher speed factor
}

--- @class bt.HealthBar
bt.HealthBar = meta.new_type("HealthBar", rt.Widget, rt.Animation, function(entity)
    local out = meta.new(bt.HealthBar, {
        _elapsed = 1,
        _hp_current = -1,
        _hp_target = -1,
        _hp_max = -1,

        _level_bar = rt.LevelBar(0, entity:get_hp(), entity:get_hp_base()),
        _label_left = {},  -- rt.Glyph
        _label_center = {},
        _label_right = {},

        _use_percentage = true,
        _state = entity:get_state(),
    })
    out._level_bar:set_corner_radius(rt.settings.battle.health_bar.corner_radius)
    return out
end)

--- @brief [internal]
function bt.HealthBar:_format_hp(value, max)
    if self._state == bt.EntityState.KNOCKED_OUT then
        return "", "KNOCKED OUT", ""
    elseif self._state == bt.EntityState.DEAD then
        return "", "DEAD", ""
    elseif self._use_percentage then
        return "", value .. " %", ""
    else
        return tostring(clamp(value, 0, max)), " / ", tostring(max)
    end
end

--- @brief
function bt.HealthBar:_update_color_from_precentage(value)
    local settings = rt.settings.battle.health_bar
    local color
    if value < 0.01 then
        color = settings.hp_color_0
    elseif value < 0.10 then
        color = settings.hp_color_10
    elseif value < 0.50 then
        color = settings.hp_color_50
    elseif value < 1 then
        color = settings.hp_color_75
    else
        color = settings.hp_color_100
    end
    self._level_bar:set_color(color, rt.color_darken(color, 0.25))
end

--- @brief [internal]
function bt.HealthBar:_update_value()
    local left, center, right = self:_format_hp(self._hp_current, self._hp_max)
    self._label_left:set_text(left)
    self._label_center:set_text(center)
    self._label_right:set_text(right)
    self._level_bar:set_value(self._hp_current)
end

--- @override
function bt.HealthBar:realize()
    if self._is_realized == true then return end

    local left, center, right = self:_format_hp(self._hp_current, self._hp_max)
    local settings = {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    }

    self._label_left = rt.Glyph(rt.settings.battle.health_bar.hp_font, left, settings)
    self._label_center = rt.Glyph(rt.settings.battle.health_bar.hp_font, center, settings)
    self._label_right = rt.Glyph(rt.settings.battle.health_bar.hp_font, right, settings)
    self._level_bar:realize()

    self:set_is_animated(true)
    self:update(0)
    self._is_realized = true
end

--- @override
function bt.HealthBar:size_allocate(x, y, width, height)
    local center_w, h1 = self._label_center:get_size()
    local left_w, h2 = self._label_left:get_size()
    local right_w, h3 = self._label_right:get_size()
    local label_h = math.max(h1, h2, h3)

    local old_center_x = x + 0.5 * width
    local total_w = left_w + center_w + right_w
    if width < total_w + rt.settings.margin_unit then width = total_w + rt.settings.margin_unit end
    x = old_center_x - 0.5 * width

    self._level_bar:fit_into(x, y, width, height)

    local label_y = y + 0.5 * height - 0.5 * label_h
    self._label_center:set_position(x + 0.5 * width - 0.5 * center_w, label_y)
    self._label_left:set_position(x + 0.5 * width - 0.5 * center_w - left_w, label_y)
    self._label_right:set_position(x + 0.5 * width + 0.5 * center_w, label_y)

    self._debug_outline = rt.Rectangle(
        x, y, width, height
    )
    self._debug_outline:set_is_outline(true)
end

--- @override
function bt.HealthBar:update(delta)
    if self._is_realized == true then
        self._elapsed = self._elapsed + delta

        local diff = self._hp_current - self._hp_target
        local speed = 1 + rt.settings.battle.health_bar.tick_acceleration * (math.abs(diff) / self._hp_max)
        local tick_duration = 1 / (rt.settings.battle.health_bar.tick_speed * speed)

        if self._elapsed > tick_duration then
            local offset = math.modf(self._elapsed, self._tick_duration)
            if diff > 0 then
                self._hp_current = self._hp_current - offset
            elseif diff < 0 then
                self._hp_current = self._hp_current + offset
            end
            self._elapsed = self._elapsed - offset * tick_duration
        end

        if diff ~= 0 then
            self:_update_value()
            self:_update_color_from_precentage(self._hp_current / self._hp_max)
            self:reformat()
        end
    end

    -- pulsing red animation
    if self._state == bt.EntityState.KNOCKED_OUT then
        local offset = rt.settings.battle.priority_queue_element.knocked_out_pulse(self._elapsed)
        local color = rt.rgba_to_hsva(rt.Palette.KNOCKED_OUT)
        color.v = clamp(color.v + offset, 0, 1)
        self._level_bar:set_color(rt.color_darken(color, 0.15), color) -- sic, keep background lighter
    end
end

--- @override
function bt.HealthBar:draw()
    if self._is_realized == true then
        self._level_bar:draw()
        self._label_left:draw()
        self._label_center:draw()
        self._label_right:draw()

        if rt.settings.debug_draw_enabled == true then
            self._debug_outline:draw()
        end
    end
end

--- @brief
function bt.HealthBar:set_value(hp, hp_max)
    self._hp_target = math.ceil(hp)
    if hp_max ~= nil then
        self._hp_max = hp_max
    end
end

--- @brief
function bt.HealthBar:set_state(state)
    self._state = state
    if self._is_realized == true then
        self:_update_color_from_precentage(self._hp_current)
    end
end

--- @brief
function bt.HealthBar:synchronize(entity)
    self._hp_target = entity:get_hp()
    self._hp_current = entity:get_hp()
    self._hp_max = entity:get_hp_base()

    local left, center, right = self:_format_hp(self._hp_current, self._hp_max)
    self._label_left:set_text(left)
    self._label_center:set_text(center)
    self._label_right:set_text(right)
    self._level_bar:set_value(self._hp_current)
    self:_update_color_from_precentage(self._hp_current / self._hp_max)
    self:_update_value()
end

--- @brief
function bt.HealthBar:set_use_percentage(b)
    self._use_percentage = b
    self:_update_value()
end

--- @brief
function bt.HealthBar:set_opacity(alpha)
    self._opacity = alpha
    self._level_bar:set_opacity(alpha)
    for object in values(self._level_bar, self._label_left, self._label_center, self._label_right) do
        if object.set_opacity ~= nil then
            object:set_opacity(alpha)
        end
    end
end
