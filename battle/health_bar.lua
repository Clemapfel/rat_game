rt.settings.battle.health_bar = {
    hp_font = rt.Font(20, "assets/fonts/pixel.ttf"),--"assets/fonts/DejaVuSansMono/DejaVuSansMono-Bold.ttf"),
    hp_color = rt.Palette.LIGHT_GREEN_2,
    hp_background_color = rt.Palette.GREEN_3,
    corner_radius = 7,
    tick_speed = 10, -- ticks per second
    tick_acceleration = 10, -- modifies how much distance should affect tick speed, more distance = higher speed factor
}

--- @class bt.HealthBar
bt.HealthBar = meta.new_type("HealthBar", bt.BattleUI, function(entity)
    local out = meta.new(bt.HealthBar, {
        _entity = entity,
        _is_realized = false,

        _elapsed = 1,   -- sic, makes it so `update` is invoked immediately

        _hp_value = -1,
        _hp_bar = rt.LevelBar(0, entity:get_hp_base(), entity:get_hp_base()),
        _hp_label = {},         -- rt.Glyph,
        _label_center = {},  -- rt.Glyph
        _label_right = {},   -- rt.Glyph

        _use_percentage = true
    })
    out._hp_bar:set_color(
        rt.settings.battle.health_bar.hp_color,
        rt.settings.battle.health_bar.hp_background_color
    )
    out._hp_bar:set_corner_radius(rt.settings.battle.health_bar.corner_radius)
    return out
end)

--- @brief [internal]
function bt.HealthBar:_format_hp(value, max)
    if self._use_percentage then
        return "", value .. " %", ""
    else
        return tostring(value), "/", tostring(max)
    end
end

--- @override
function bt.HealthBar:realize()
    if self._is_realized then return end

    local left, center, right = self:_format_hp(self._hp_value, self._entity:get_hp_base())
    local settings = {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    }

    self._label_left = rt.Glyph(rt.settings.battle.health_bar.hp_font, left, settings)
    self._label_center = rt.Glyph(rt.settings.battle.health_bar.hp_font, center, settings)
    self._label_right = rt.Glyph(rt.settings.battle.health_bar.hp_font, right, settings)
    self._hp_bar:realize()

    self:set_is_animated(true)
    self:update(0)
    self._is_realized = true
    self:reformat()
end

--- @override
function bt.HealthBar:size_allocate(x, y, width, height)
    local center_w, h1 = self._label_center:get_size()
    local left_w, h2 = self._label_left:get_size()
    local right_w, h3 = self._label_right:get_size()
    local label_h = math.max(h1, h2, h3)

    println(self._label_center._content)

    local old_center_x = x + 0.5 * width
    local total_w = left_w + center_w + right_w
    if width < total_w + rt.settings.margin_unit then width = total_w + rt.settings.margin_unit end
    x = old_center_x - 0.5 * width

    self._hp_bar:fit_into(x, y, width, height)

    local label_y = y + 0.5 * height - 0.5 * label_h
    self._label_center:set_position(x + 0.5 * width - 0.5 * center_w, label_y)
    self._label_left:set_position(x + 0.5 * width - 0.5 * center_w - left_w, label_y)
    self._label_right:set_position(x + 0.5 * width + 0.5 * center_w, label_y)
end

--- @override
function bt.HealthBar:update(delta)
    if self._is_realized then
        self._elapsed = self._elapsed + delta

        local diff = (self._hp_value - self._entity:get_hp())
        local speed = (1 + rt.settings.battle.health_bar.tick_acceleration * (math.abs(diff) / self._entity:get_hp_base()))
        local tick_duration = 1 / (rt.settings.battle.health_bar.tick_speed * speed)
        if self._elapsed > tick_duration then
            local offset = math.modf(self._elapsed, self._tick_duration)
            if diff > 0 then
                self._hp_value = self._hp_value - offset
            elseif diff < 0 then
                self._hp_value = self._hp_value + offset
            end
            self._elapsed = self._elapsed - offset * tick_duration

            if diff ~= 0 then
                local left, center, right = self:_format_hp(self._hp_value, self._entity:get_hp_base())
                self._label_left:set_text(left)
                self._label_center:set_text(center)
                self._label_right:set_text(right)
                self._hp_bar:set_value(self._hp_value)
                self:reformat()
            end
        end
    end
end

--- @override
function bt.HealthBar:draw()
    if self._is_realized then
        self._hp_bar:draw()
        self._label_left:draw()
        self._label_center:draw()
        self._label_right:draw()
    end
end

--- @override
function bt.HealthBar:sync()
    self._hp_value = self._entity:get_hp()
    self._label_left:set_text(select(1, self:_format_hp(self._hp_value, self._entity:get_hp_base())))
    self._hp_bar:set_value(self._hp_value)
end
