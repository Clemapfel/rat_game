rt.settings.party_info = {
    spd_font = rt.Font(40, "assets/fonts/pixel.ttf"),
    hp_font = rt.Font(20, "assets/fonts/pixel.ttf"),
    base_color = rt.Palette.GREY_6,
    frame_color = rt.Palette.GREY_5
}

--- @class bt.StatLevelIndicator
bt.StatLevelIndicator = meta.new_type("StatLevelIndicator", function(level)
    if meta.is_nil(bt.PartyInfo.spritesheet) then
        bt.PartyInfo.spritesheet = rt.Spritesheet("assets/sprites", "party_info")
    end

    local out = meta.new(bt.StatLevelIndicator, {
        _sprite = rt.Sprite(bt.PartyInfo.spritesheet, "neutral")
    }, rt.Drawable, rt.Widget)
    out:set_level(level)
    return out
end)

--- @overload
function bt.StatLevelIndicator:get_top_level_widget()
    return self._sprite
end

function bt.StatLevelIndicator:draw()
    self._sprite:draw()
end

--- @brief
function bt.StatLevelIndicator:set_level(level)
    local id = "neutral"
    if level > 3 then
        id = "up_infinite"
    elseif level == 3 then
        id = "up_3"
    elseif level == 2 then
        id = "up_2"
    elseif level == 1 then
        id = "up_1"
    elseif level == 0 then
        id = "neutral"
    elseif level == -1 then
        id = "down_1"
    elseif level == -2 then
        id = "down_2"
    elseif level == -3 then
        id = "down_3"
    elseif level < -4 then
        id = "down_infinite"
    end

    self._sprite:set_animation(id)
end

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
        _hp_bar = rt.LevelBar(0, entity:get_hp_base(), entity:get_hp()),
        _attack_indicator = bt.StatLevelIndicator(entity:get_attack_level()),
        _defense_indicator = bt.StatLevelIndicator(entity:get_defense_level()),
        _speed_indicator = bt.StatLevelIndicator(entity:get_speed_level()),
        _indicator_base = rt.Spacer(),
        _indicator_base_frame = rt.Frame(),
    }, rt.Drawable, rt.Widget)

    local hp_content = tostring(entity:get_hp()) .. " / " .. tostring(entity:get_hp_base())
    out._hp_label = rt.Glyph(rt.settings.party_info.hp_font, hp_content, {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    })

    out._speed_label = rt.Glyph(rt.settings.party_info.spd_font, tostring(entity:get_speed()), {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.SPEED
    })

    out._hp_bar:set_color(rt.Palette.HP)

    out._frame:set_child(out._base)

    out._base:set_color(rt.settings.party_info.base_color)
    out._frame:set_color(rt.settings.party_info.frame_color)
    out._h_rule:set_color(rt.settings.party_info.frame_color)
    out._h_rule:set_minimum_size(0, out._frame:get_thickness())
    out._h_rule:set_color(out._frame._frame:get_color(), out._frame._frame_outline:get_color())

    out._indicator_base_frame:set_child(out._indicator_base)
    out._indicator_base:set_color(rt.Palette.GREY_5)
    out._indicator_base_frame:set_color(rt.Palette.GREY_4)

    out._attack_indicator._sprite:set_color(rt.Palette.ATTACK)
    out._defense_indicator._sprite:set_color(rt.Palette.DEFENSE)
    out._speed_indicator._sprite:set_color(rt.Palette.SPEED)

    return out
end)

--- @overload rt.Wiget.size_allocate
function bt.PartyInfo:size_allocate(x, y, width, height)
    self._base:fit_into(x, y, width, height)
    self._frame:fit_into(x, y, width, height)

    local m = rt.settings.margin_unit
    self._hp_bar:fit_into(x + m, y + m, width - 2 * m, rt.settings.party_info.spd_font:get_size() )
    local hp_x, hp_y = self._hp_bar:get_position()
    local hp_w, hp_h = self._hp_bar:get_size()
    local label_w, label_h = self._hp_label:get_size()
    self._hp_label:set_position(hp_x + 0.5 * hp_w - 0.5 * label_w, hp_y + 0.5 * hp_h - 0.5 * label_h)

    self._h_rule:set_expand_vertically(false)
    self._h_rule:fit_into(x, hp_y + hp_h + m, width, select(2, self._h_rule:get_minimum_size()))

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