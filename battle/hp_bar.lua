rt.settings.battle.health_bar = {
    hp_font = rt.Font(30, "assets/fonts/pixel.ttf"),
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
        
        _elapsed = 0,

        _hp_value = -1,
        _hp_value_max = entity:get_hp_base(),
        _hp_bar = rt.LevelBar(0, entity:get_hp_base(), entity:get_hp_base()),
        _hp_label = {}, -- rt.Glyph,
        _hp_label_right = {}, -- rt.Glyph
    })
    out._hp_bar:set_color(
        rt.settings.battle.health_bar.hp_color,
        rt.settings.battle.health_bar.hp_background_color
    )
    out._hp_bar:set_corner_radius(rt.settings.battle.health_bar.corner_radius)
    return out
end)

--- @brief [internal]
function bt.HealthBar._format_hp(value, max)
    max = tostring(max)
    local current = tostring(value)
    current = string.rep(" ", (#max - #current)) .. current
    return current, "  / " .. max
end

--- @override
function bt.HealthBar:realize()
    if self._is_realized then return end

    local left, right = self._format_hp(self._hp_value, self._hp_value_max)
    local settings = {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    }

    self._hp_label_left = rt.Glyph(rt.settings.battle.health_bar.hp_font, left, settings)
    self._hp_label_right = rt.Glyph(rt.settings.battle.health_bar.hp_font, right, settings)
    self._hp_bar:realize()

    self:set_is_animated(true)
    self._is_realized = true
end

--- @override
function bt.HealthBar:size_allocate(x, y, width, height)
    local left_w, left_h = self._hp_label_left:get_size()
    local right_w, right_h = self._hp_label_right:get_size()

    local m = rt.settings.margin_unit
    local w, h = width, height
    local hp_label_w, hp_label_h = left_w + right_w, math.max(left_h, right_h)
    local hp_x = x + m
    local hp_y = y + m
    local hp_w = w - 2 * m
    local hp_h = hp_label_h + m
    self._hp_bar:fit_into(hp_x, hp_y, hp_w, hp_h)

    local hp_label_x = hp_x + 0.5 * hp_w - 0.5 * hp_label_w
    local hp_label_y = hp_y + 0.5 * hp_h - 0.5 * hp_label_h
    self._hp_label_left:set_position(hp_label_x, hp_label_y)
    self._hp_label_right:set_position(hp_label_x + left_w, hp_label_y)
end

--- @override
function bt.HealthBar:update(delta)
    if self._is_realized then
        local current = self._hp_value
        local target = self._entity:get_hp()
        local diff = (current - target)

        self._elapsed = self._elapsed + delta

        local max_hp = self._entity:get_hp_base()
        local speed = (1 + rt.settings.battle.health_bar.tick_acceleration * (math.abs(diff) / max_hp))
        local tick_duration = 1 / (rt.settings.battle.health_bar.tick_speed * speed)
        local should_update = false
        while self._elapsed > tick_duration do
            if diff > 0 then
                self._hp_value = self._hp_value - 1
            elseif diff < 0 then
                self._hp_value = self._hp_value + 1
            end
            self._elapsed = self._elapsed - tick_duration
            should_update = true
        end

        if should_update then
            self._hp_label_left:set_text(select(1, self._format_hp(self._hp_value, self._entity:get_hp_base())))
            self._hp_bar:set_value(self._hp_value)
        end
    end
end

--- @override
function bt.HealthBar:draw()
    if self._is_realized then
        self._hp_bar:draw()
        self._hp_label_left:draw()
        self._hp_label_right:draw()
    end
end

