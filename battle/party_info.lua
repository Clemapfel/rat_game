rt.settings.party_info = {
    spd_font = rt.Font(40, "assets/fonts/pixel.ttf"),
    hp_font = rt.Font(30, "assets/fonts/pixel.ttf"),
    base_color = rt.Palette.GREY_6,
    frame_color = rt.Palette.GREY_5,
    tick_speed_base = 100, -- 1 point per second
    tick_speed_acceleration_factor = 10,
    speed_label_width = -1,

    bounce_function = function(x) return -1 * (math.mod(2 / math.pi * x, 2) - 1)^2 + 1 end,
    bounce_offset = 50,
    bounce_frequency = 3.5,
}


--- @class bt.PartyInfo
bt.PartyInfo = meta.new_type("PartyInfo", function(entity)
    meta.assert_isa(entity, bt.Entity)

    if meta.is_nil(env.party_info_spritesheet) then
        env.party_info_spritesheet = rt.Spritesheet("assets/sprites", "party_info")
    end

    if rt.settings.party_info.speed_label_width == -1 then
        rt.settings.party_info.speed_label_width = rt.Glyph(rt.settings.party_info.spd_font, "0000", {
            is_outlined = true,
            outline_color = rt.Palette.TRUE_BLACK,
            color = rt.Palette.SPEED
        }):get_size()
    end

    local out = meta.new(bt.PartyInfo, {
        _entity = entity,
        _hp_label = {},  -- rt.Glyph
        _hp_label_right = {},
        _hp_value = -1,
        _speed_label = {}, -- rt.Glyph
        _speed_value = -1,
        _base = rt.Spacer(),
        _frame = rt.Frame(),
        _h_rule = rt.Spacer(),
        _v_rule = rt.Spacer(),
        _hp_bar = rt.LevelBar(0, entity:get_hp_base(), entity:get_hp()),
        _attack_indicator = bt.StatLevelIndicator(entity:get_attack_level()),
        _defense_indicator = bt.StatLevelIndicator(entity:get_defense_level()),
        _speed_indicator = bt.StatLevelIndicator(entity:get_speed_level()),
        _indicator_base = rt.Spacer(),
        _indicator_base_frame = rt.Frame(),
        _status_area = rt.FlowLayout(),
        _elapsed = 0,
        _bounce_offset = 0,
        _bounce_elapsed = 0,
        _is_bouncing = true
    }, rt.Drawable, rt.Widget, rt.Animation)

    local left, right = out:_format_hp(entity:get_hp())
    local settings = {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    }

    out._hp_label_left = rt.Glyph(rt.settings.party_info.hp_font, left, settings)
    out._hp_label_right = rt.Glyph(rt.settings.party_info.hp_font, right, settings)
    out._hp_value = entity:get_hp()


    out._speed_label = rt.Glyph(rt.settings.party_info.spd_font, out:_format_speed(entity:get_speed()), {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.SPEED
    })
    out._speed_value = entity:get_speed()

    out._hp_bar:set_color(rt.Palette.PURPLE_2, rt.Palette.PURPLE_4)
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

    out._status_area:set_horizontal_alignment(rt.Alignment.START)
    out:_update_status_ailments()

    out._entity:signal_connect("changed", function(entity, self)
        self._attack_indicator:set_level(entity:get_attack_level())
        self._defense_indicator:set_level(entity:get_defense_level())
        self._speed_indicator:set_level(entity:get_speed_level())
    end, out)

    return out
end)

--- @brief
function bt.PartyInfo:_update_status_ailments()

    local thumbnails = {}
    for _, status in pairs(self._entity:get_status_ailments()) do
        table.insert(thumbnails, bt.StatusThumbnail(status, status.max_duration - self._entity:_get_status_ailment_elapsed(status)))
    end

    self._status_area:set_children(thumbnails)
end

--- @brief [internal]
function bt.PartyInfo:_format_speed(value)
    self._speed_value = value

    value = clamp(value, 0, 9999)
    return string.rep("0", math.abs(#tostring(value) - 4)) .. tostring(value)
end

--- @brief [internal]
function bt.PartyInfo:_format_hp(value)
    self._hp_bar:set_value(value)
    local max = tostring(self._entity:get_hp_base())
    local current = tostring(value)

    current = string.rep(" ", (#max - #current)) .. current
    return current, " / " .. max
end

--- @overload
function bt.PartyInfo:update(delta)

    self._elapsed = self._elapsed + delta

    local tick_length = 1 / rt.settings.party_info.tick_speed_base
    local update_hp, update_speed = false, false
    while self._elapsed > tick_length do
        do
            local current = self._hp_value
            local target = self._entity:get_hp()
            local acceleration = 1
            acceleration = math.round(acceleration + rt.settings.party_info.tick_speed_acceleration_factor *  math.abs(target - current) / math.abs(self._entity:get_hp_base()))

            if current < target then
                if math.abs(current - target) < acceleration then
                    self._hp_value = target
                else
                    self._hp_value = self._hp_value + acceleration
                end
                update_hp = true
            elseif current > target then
                if math.abs(current - target) < acceleration then
                    self._hp_value = target
                else
                    self._hp_value = self._hp_value - acceleration
                end
                update_hp = true
            end
        end

        do
            local current = self._speed_value
            local target = self._entity:get_speed()
            local acceleration = 1
            acceleration = math.round(acceleration + rt.settings.party_info.tick_speed_acceleration_factor *  math.abs(target - current) / math.abs(self._entity:get_speed_base()))

            if current < target then
                if math.abs(current - target) < acceleration then
                    self._speed_value = target
                else
                    self._speed_value = self._speed_value + acceleration
                end
                update_speed = true
            elseif current > target then
                if math.abs(current - target) < acceleration then
                    self._speed_value = target
                else
                    self._speed_value = self._speed_value - acceleration
                end
                update_speed = true
            end
        end

        self._elapsed = self._elapsed - tick_length
    end

    if update_hp then
        self._hp_label_left:set_text(select(1, self:_format_hp(self._hp_value)))
    end

    if update_speed then
        self._speed_label:set_text(self:_format_speed(self._speed_value))
    end

    self._bounce_elapsed = self._bounce_elapsed + delta
    self._bounce_offset = -1 * rt.settings.party_info.bounce_function(self._bounce_elapsed * rt.settings.party_info.bounce_frequency) * rt.settings.party_info.bounce_offset
end

--- @overload rt.Wiget.size_allocate
function bt.PartyInfo:size_allocate(x, y, width, height)

    local m = rt.settings.margin_unit
    local label_w, label_h = rt.settings.party_info.speed_label_width, select(2, self._speed_label:get_size())
    local rule_thickness = 5 --select(2, self._h_rule:get_minimum_size())
    local indicator_spacing = 0.5 * m
    local w = 3 * select(1, self._attack_indicator:get_size()) + 2 * indicator_spacing + 2 * m + rule_thickness + label_w + 2 * m + m
    local h = (label_h + 2 * m) * 2 - m

    local h_align, v_align = self:get_horizontal_alignment(), self:get_vertical_alignment()
    if h_align == rt.Alignment.START then
        x = x
    elseif h_align == rt.Alignment.CENTER then
        x = x + 0.5 * width - 0.5 * w
    elseif h_align == rt.Alignment.END then
        x = x + width - w
    end

    if v_align == rt.Alignment.START then
        y = y
    elseif v_align == rt.Alignment.CENTER then
        y = y + 0.5 * height - 0.5 * h
    elseif v_align == rt.Alignment.END then
        y = y + height - h
    end

    local left_w, left_h = self._hp_label_left:get_size()
    local right_w, right_h = self._hp_label_right:get_size()

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

    local h_rule_y = y + hp_h + 2 * m
    self._h_rule:fit_into(x, h_rule_y, w, rule_thickness)

    local sprite_size = self._attack_indicator._sprite:get_resolution() * 3
    local indicator_area = rt.AABB(hp_x, y + 2 * m + hp_h + rule_thickness + 0.5 * m, sprite_size, sprite_size)
    for _, indicator in pairs({self._attack_indicator, self._defense_indicator, self._speed_indicator}) do
        indicator:fit_into(indicator_area)
        indicator_area.x = indicator_area.x + indicator_area.width + indicator_spacing
    end

    indicator_area.x = indicator_area.x - indicator_spacing

    self._speed_label:set_position(hp_x + hp_w - label_w, indicator_area.y + 0.5 * indicator_area.height - 0.5 * label_h)

    self._frame:set_thickness(rule_thickness - 2)
    self._frame:fit_into(x - rule_thickness, y - rule_thickness, w + 2 * rule_thickness, h + 2 * rule_thickness)

    local status_h = select(2, self._status_area:measure())
    self._status_area:fit_into(x - rule_thickness, y - rule_thickness - status_h , w + 2 * rule_thickness, h + 2 * rule_thickness)

    local v_rule_left = indicator_area.x
    local v_rule_right = select(1, self._speed_label:get_position())
    local v_rule_x = v_rule_left + 0.5 * (v_rule_right - v_rule_left) - 0.5 * rule_thickness
    self._v_rule:fit_into(v_rule_x, h_rule_y, rule_thickness, y + h - h_rule_y )
end

--- @overload rt.Drawable.draw
function bt.PartyInfo:draw()

    love.graphics.push()

    if self._is_bouncing then
        love.graphics.translate(0, self._bounce_offset)
    end

    self._frame:draw()
    self._hp_bar:draw()
    self._hp_label_left:draw()
    self._hp_label_right:draw()

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
    self._status_area:draw()

    if self:get_is_selected() then
        self._base:draw_selection_indicator()
    end

    love.graphics.pop()

end

--- @overload rt.Widget.realize
function bt.PartyInfo:realize()
    for _, widget in pairs(getmetatable(self).properties) do
        if meta.is_widget(widget) then
            widget:realize()
        end
    end
    self._hp_bar:set_value(self._entity:get_hp())
    rt.Widget.realize(self)
    self:set_is_animated(true)
end
