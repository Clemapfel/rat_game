rt.settings.battle.health_bar = {
    hp_font = rt.settings.font.default_mono_small,

    hp_color_100 = rt.Palette.MINT_2,
    hp_color_75 = rt.Palette.GREEN_1,
    hp_color_50 = rt.Palette.YELLOW_2,
    hp_color_25 = rt.Palette.YELLOW_2,
    hp_color_10 = rt.Palette.YELLOW_2,
    hp_color_0 = rt.Palette.YELLOW_2,

    hp_background_color = rt.Palette.GREEN_3,
    scroll_speed = 200,
}

--- @class bt.HealthBar
bt.HealthBar = meta.new_type("HealthBar", rt.Widget, rt.Updatable, function(lower, upper, value)
    if value == nil then value = lower + (upper - lower) / 2 end
    return meta.new(bt.HealthBar, {
        _lower = lower,
        _upper = upper,
        _current_value = value,
        _target_value = value,

        _shape = rt.Rectangle(0, 0, 1, 1),
        _shape_outline = rt.Line(0, 0, 1, 1),
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _backdrop_outline = rt.Rectangle(0, 0, 1, 1),
        _stencil = rt.Rectangle(0, 0, 1, 1),

        _label_left = {},   -- rt.Label
        _label_center = {}, -- rt.Label
        _label_right = {},  -- rt.Label
        _use_percentage = true,
        _state = bt.EntityState.ALIVE,

        _value_animation = rt.SmoothedMotion1D(value, rt.settings.battle.health_bar.scroll_speed),

        _opacity = 1
    })
end)

--- @override
function bt.HealthBar:realize()
    if self:already_realized() then return end

    for outline in range(self._backdrop_outline, self._shape_outline) do
        outline:set_is_outline(true)
        outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    end

    self._backdrop:set_corner_radius(rt.settings.frame.corner_radius)
    self._backdrop_outline:set_corner_radius(rt.settings.frame.corner_radius)

    self._backdrop_outline:set_line_width(1)
    self._shape_outline:set_line_width(2)

    local left, center, right = self:_format_hp(self._current_value, self._upper)
    local settings = {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    }

    local format_prefix = "<o>"
    local format_postfix = "</o>"

    self._label_left = rt.Label(format_prefix .. left .. format_postfix, rt.settings.battle.health_bar.hp_font)
    self._label_center = rt.Label(format_prefix .. center .. format_postfix, rt.settings.battle.health_bar.hp_font)
    self._label_right = rt.Label(format_prefix .. right .. format_postfix, rt.settings.battle.health_bar.hp_font)

    for label in range(self._label_left, self._label_center, self._label_right) do
        label:set_justify_mode(rt.JustifyMode.LEFT)
        label:realize()
    end

    self:_update_value()
end

--- @brief [internal]
function bt.HealthBar:_format_hp(value, max)
    if self._state == bt.EntityState.KNOCKED_OUT then
        return "", rt.Translation.battle.health_bar_knocked_out_label, ""
    elseif self._state == bt.EntityState.DEAD then
        return "", rt.Translation.battle.health_bar_dead_label, ""
    elseif self._use_percentage then
        return "", (value - math.fmod(value, 1.0)) .. " %", ""
    else
        return tostring(math.round(clamp(value, 0, max))), " / ", tostring(max)
    end
end

--- @brief
function bt.HealthBar:_update_value()
    local x, y = self._backdrop:get_top_left()
    local width, height = self._backdrop:get_size()
    local bounds = rt.AABB(x, y, ((self._current_value - self._lower) / (self._upper - self._lower)) * width, height)
    bounds = rt.AABB(math.floor(bounds.x), math.floor(bounds.y), math.floor(bounds.width), math.floor(bounds.height))
    self._shape:resize(bounds)
    self._shape_outline:resize(bounds.x + bounds.width, bounds.y, bounds.x + bounds.width, bounds.y + bounds.height)

    local settings = rt.settings.battle.health_bar
    local color
    if self._current_value < 0.01 then
        color = settings.hp_color_0
    elseif self._current_value < 0.10 then
        color = settings.hp_color_10
    elseif self._current_value < 0.50 then
        color = settings.hp_color_50
    elseif self._current_value < 1 then
        color = settings.hp_color_75
    else
        color = settings.hp_color_100
    end
    self._shape:set_color(color)
    self._backdrop:set_color(rt.color_darken(color, 0.25))

    local left, center, right = self:_format_hp(self._current_value, self._upper)
    local format_prefix, format_postfix = "<o>", "</o>"
    self._label_left:set_text(format_prefix .. left .. format_postfix)
    self._label_center:set_text(format_prefix .. center .. format_postfix)
    self._label_right:set_text(format_prefix .. right .. format_postfix)
end

--- @override
function bt.HealthBar:size_allocate(x, y, width, height)
    self._backdrop:resize(x, y, width, height)
    self._backdrop_outline:resize(x, y, width, height)

    local center_w, h1 = self._label_center:measure()
    local left_w, h2 = self._label_left:measure()
    local right_w, h3 = self._label_right:measure()
    local label_h = math.max(h1, h2, h3)

    local label_y = y + 0.5 * height - 0.5 * label_h
    self._label_center:fit_into(x + 0.5 * width - 0.5 * center_w, label_y, POSITIVE_INFINITY)
    self._label_left:fit_into(x + 0.5 * width - 0.5 * center_w - left_w, label_y, POSITIVE_INFINITY)
    self._label_right:fit_into(x + 0.5 * width + 0.5 * center_w, label_y, POSITIVE_INFINITY)

    self:_update_value()
end

--- @override
function bt.HealthBar:draw()
    if self._is_realized == false then return end

    local stencil_value = meta.hash(bt.HealthBar) % 254 + 2
    self._backdrop:draw()
    rt.graphics.stencil(stencil_value, function()
        self._backdrop:draw()
    end)

    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)
    self._shape:draw()
    self._shape_outline:draw()
    rt.graphics.set_stencil_test()
    self._backdrop_outline:draw()

    self._label_left:draw()
    self._label_center:draw()
    self._label_right:draw()
end

--- @brief
function bt.HealthBar:update(delta)
    if self._is_realized ~= true then return end

    self._value_animation:update(delta)
    self._current_value = math.ceil(self._value_animation:get_value())
    self:_update_value()
end

--- @brief
function bt.HealthBar:set_opacity(alpha)
    self._opacity = alpha
    self._shape:set_opacity(alpha)
    self._shape_outline:set_opacity(alpha)
    self._backdrop:set_opacity(alpha)
    self._backdrop_outline:set_opacity(alpha)
end

--- @brief
function bt.HealthBar:set_value(value, upper)
    if upper ~= nil then self._upper = upper end
    value = clamp(value, self._lower, self._upper)
    self._target_value = value
    self._value_animation:set_target_value(self._target_value)
end

--- @brief
function bt.HealthBar:get_value()
    return self._target_value
end

--- @brief
function bt.HealthBar:skip()
    self._current_value = self._target_value
    if self._is_realized then
        self:_update_value()
    end
end
