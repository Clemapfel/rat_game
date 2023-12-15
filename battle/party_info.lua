rt.settings.party_info = {
    spd_font = rt.Font(40, "assets/fonts/pixel.ttf"),
    hp_font = rt.Font(30, "assets/fonts/pixel.ttf"),
    base_color = rt.Palette.GREY_6,
    frame_color = rt.Palette.GREY_5
}

--- @class bt.PartyInfo
bt.PartyInfo = meta.new_type("PartyInfo", function(entity)
    meta.assert_isa(entity, bt.Entity)

    if meta.is_nil(env.party_info_spritesheet) then
        env.party_info_spritesheet = rt.Spritesheet("assets/sprites", "party_info")
    end

    local out = meta.new(bt.PartyInfo, {
        _entity = entity,
        _hp_label = {},  -- rt.Glyph
        _speed_label = {}, -- rt.Glyph
        _base = rt.Spacer(),
        _frame = rt.Frame(),
        _h_rule = rt.Spacer(),
        _v_rule = rt.Spacer(),
        _hp_bar = rt.LevelBar(0, entity:get_hp_base(), entity:get_hp()),
        _attack_indicator = bt.StatLevelIndicator(entity:get_attack_level()),
        _defense_indicator = bt.StatLevelIndicator(entity:get_defense_level()),
        _speed_indicator = bt.StatLevelIndicator(entity:get_speed_level()),
        _indicator_base = rt.Spacer(),
        _indicator_base_frame = rt.Frame()
    }, rt.Drawable, rt.Widget)

    local hp_content = tostring(entity:get_hp()) .. " / " .. tostring(entity:get_hp_base())
    out._hp_label = rt.Glyph(rt.settings.party_info.hp_font, hp_content, {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    })

    out._speed_label = rt.Glyph(rt.settings.party_info.spd_font, out._format_speed(entity:get_speed()), {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.SPEED
    })

    out._hp_bar:set_color(rt.Palette.HP)

    out._frame:set_child(out._base)

    out._base:set_color(rt.settings.party_info.base_color)
    out._frame:set_color(rt.settings.party_info.frame_color)

    for _, rule in pairs({out._h_rule, out._v_rule}) do
        rule:set_color(rt.settings.party_info.frame_color)
        rule:set_color(out._frame._frame:get_color(), out._frame._frame_outline:get_color())
    end

    out._h_rule:set_minimum_size(0, out._frame:get_thickness())
    out._v_rule:set_minimum_size(out._frame:get_thickness(), 0)

    out._indicator_base_frame:set_child(out._indicator_base)
    out._indicator_base:set_color(rt.Palette.GREY_5)
    out._indicator_base_frame:set_color(rt.Palette.GREY_4)

    out._attack_indicator._sprite:set_color(rt.Palette.ATTACK)
    out._defense_indicator._sprite:set_color(rt.Palette.DEFENSE)
    out._speed_indicator._sprite:set_color(rt.Palette.SPEED)

    return out
end)

--- @brief [internal]
function bt.PartyInfo._format_speed(value)
    value = clamp(value, 0, 9999)
    return string.rep("0", math.abs(#tostring(value) - 4)) .. tostring(value)
end

--- @overload rt.Wiget.size_allocate
function bt.PartyInfo:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit

    local label_w, label_h = self._speed_label:get_size()
    local rule_thickness = 5 --select(2, self._h_rule:get_minimum_size())
    local indicator_spacing = 0.5 * m
    local w = 3 * select(1, self._attack_indicator:get_size()) + 2 * indicator_spacing + 2 * m + rule_thickness + label_w + 2 * m + m

    local hp_label_w, hp_label_h = self._hp_label:get_size()
    local hp_x = x + m
    local hp_y = y + m
    local hp_w = w - 2 * m
    local hp_h = hp_label_h + m
    self._hp_bar:fit_into(hp_x, hp_y, hp_w, hp_h)
    self._hp_label:set_position(hp_x + 0.5 * hp_w - 0.5 * hp_label_w, hp_y + 0.5 * hp_h - 0.5 * hp_label_h)

    local h_rule_y = y + hp_h + 2 * m
    self._h_rule:fit_into(x, h_rule_y, w, rule_thickness)

    local sprite_size = self._attack_indicator._sprite:get_resolution() * 3
    local indicator_area = rt.AABB(hp_x, y + 2 * m + hp_h + rule_thickness + 0.5 * m + 0.5 * sprite_size, sprite_size, sprite_size)
    for _, indicator in pairs({self._attack_indicator, self._defense_indicator, self._speed_indicator}) do
        indicator:fit_into(indicator_area)
        indicator_area.x = indicator_area.x + indicator_area.width + indicator_spacing
    end

    indicator_area.x = indicator_area.x - indicator_spacing

    self._speed_label:set_position(hp_x + hp_w - label_w, indicator_area.y + 0.5 * indicator_area.height - 0.5 * label_h)

    local h = select(2, self._speed_label:get_position()) + select(2, self._speed_label:get_size()) - y + 0.5 * m
    self._frame:set_thickness(rule_thickness - 2)
    self._frame:fit_into(x - rule_thickness, y - rule_thickness, w + 2 * rule_thickness, h + 2 * rule_thickness)

    local v_rule_left = indicator_area.x
    local v_rule_right = select(1, self._speed_label:get_position())
    local v_rule_x = v_rule_left + 0.5 * (v_rule_right - v_rule_left) - 0.5 * rule_thickness
    self._v_rule:fit_into(v_rule_x, h_rule_y, rule_thickness, y + h - h_rule_y )

    --[[
    self._base:fit_into(x, y, width, height)
    self._frame:fit_into(x, y, width, height)

    local m = rt.settings.margin_unit
    self._hp_bar:fit_into(x + m, y + m, width - 2 * m, rt.settings.party_info.spd_font:get_size() )
    local hp_x, hp_y = self._hp_bar:get_position()
    local hp_w, hp_h = self._hp_bar:get_size()
    local label_w, label_h = self._hp_label:get_size()
    self._hp_label:set_position(hp_x + 0.5 * hp_w - 0.5 * label_w, hp_y + 0.5 * hp_h - 0.5 * label_h)

    self._h_rule:set_expand_vertically(false)
    local h_rule_y = hp_y + hp_h + m
    self._h_rule:fit_into(x, h_rule_y, width, select(2, self._h_rule:get_minimum_size()))

    local sprite_size = self._attack_indicator._sprite:get_resolution() * 3
    local indicator_area = rt.AABB(x + m, y + height -  m - sprite_size, sprite_size, sprite_size)
    local indicator_base_x = indicator_area.x

    self._attack_indicator:fit_into(indicator_area)
    indicator_area.x = indicator_area.x + sprite_size
    self._defense_indicator:fit_into(indicator_area)
    indicator_area.x = indicator_area.x + sprite_size
    self._speed_indicator:fit_into(indicator_area)
    indicator_area.x = indicator_area.x + sprite_size

    self._indicator_base_frame:fit_into(indicator_base_x - m, indicator_area.y - m, indicator_area.width * 3 + 2 * m, indicator_area.height + 2 * m)

    label_w, label_h = self._speed_label:get_size()
    self._speed_label:set_position(x + width - label_w - 2 * m, y + height - label_h - m)

    self._v_rule:set_expand_horizontally(false)

    local indicator_right = select(1, self._speed_indicator:get_position()) + select(1, self._speed_indicator:get_size())
    local speed_left = select(1, self._speed_label:get_position())
    local v_rule_w = select(2, self._h_rule:get_minimum_size())
    local v_rule_h = select(2, self._speed_label:get_position()) + v_rule_w + select(2, self._speed_label:get_size()) - select(2, self._h_rule:get_position())

    local v_rule_x = x + 0.5 * width - 0.5 * v_rule_w
    self._v_rule:fit_into(v_rule_x, h_rule_y + v_rule_w , v_rule_w, v_rule_h)
    ]]--
end

--- @overload rt.Drawable.draw
function bt.PartyInfo:draw()
    self._frame:draw()
    self._hp_bar:draw()
    self._hp_label:draw()

    local stencil_value = 255
    love.graphics.stencil(function()
        self._frame._frame:draw()
    end, "replace", stencil_value, true)
    love.graphics.setStencilTest("notequal", stencil_value)
    self._v_rule:draw()
    self._h_rule:draw()
    love.graphics.stencil(function() end, "replace", 0, false) -- reset stencil value
    love.graphics.setStencilTest()

    --self._indicator_base_frame:draw()
    self._attack_indicator:draw()
    self._defense_indicator:draw()
    self._speed_indicator:draw()

    self._speed_label:draw()
end

--- @overload rt.Widget.realize
function bt.PartyInfo:realize()
    for _, widget in pairs(getmetatable(self).properties) do
        if meta.is_widget(widget) then
            widget:realize()
        end
    end
    rt.Widget.realize(self)
end