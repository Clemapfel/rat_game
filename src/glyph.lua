rt.settings.glyph = {
    default_background_color = rt.RGBA(0, 0, 0, 1),
    default_outline_color = rt.RGBA(0, 0, 0, 1),
    outline_thickness = 1,
    rainbow_width = 15,    -- n characters
    shake_offset = 6,      -- px
    shake_period = 15,     -- shakes per second
    wave_period = 10,      -- n chars
    wave_function = function(x) return math.sin((x * 4 * math.pi) / (2 * rt.settings.glyph.wave_period)) end,
    wave_offset = 10,      -- px
    wave_speed = 0.2      -- cycles per second
}

--- @class rt.TextEffect
rt.TextEffect = meta.new_enum({
    NONE = "TEXT_EFFECT_NONE",
    SHAKE = "TEXT_EFFECT_SHAKE",
    WAVE = "TEXT_EFFECT_WAVE",
    RAINBOW = "TEXT_EFFECT_RAINBOW",
    OUTLINE = "TEXT_EFFECT_OUTLINE"
})

--- @class rt.Glyph
--- @param font rt.Font
--- @param content String
--- @param look Table
rt.Glyph = meta.new_type("Glyph", function(font, content, look)

    meta.assert_table(look)
    local font_style = look.font_style
    local color = look.color
    local is_underlined = look.is_underlined
    local is_strikethrough = look.is_strikethrough
    local is_outlined = look.is_outlined
    local outline_color = look.outline_color
    local effects = look.effect
    local wrap_width = look.wrap_width

    if meta.is_nil(font_style) then font_style = rt.FontStyle.REGULAR end
    if meta.is_nil(color) then color = rt.RGBA(1, 1, 1, 1) end
    if meta.is_nil(effects) then effects = {} end
    if meta.is_nil(wrap_width) then wrap_width = POSITIVE_INFINITY end
    if meta.is_nil(is_underlined) then is_underlined = false end
    if meta.is_nil(is_strikethrough) then is_strikethrough = false end
    if meta.is_nil(is_outlined) then is_outlined = false end
    if meta.is_nil(outline_color) then outline_color = rt.settings.glyph.default_outline_color end
    --if meta.is_nil(has_background) then has_background = false end
    --if meta.is_nil(background_color) then background_color = rt.settings.glyph.default_outline_color end

    local out = meta.new(rt.Glyph, {
        _font = font,
        _content = content,
        _color = color,
        _style = font_style,
        _is_underlined = is_underlined,
        _is_strikethrough = is_strikethrough,
        _is_outlined = is_outlined,
        _outline_color = outline_color,
        _effects = {},
        _is_animated = false,
        _elapsed_time = 0,
        _glyph = {},
        _position_x = 0,
        _position_y = 0,
        _n_visible_chars = POSITIVE_INFINITY,
        _character_widths = {},
        _character_offsets = {},
        _effects_data = {}
    }, rt.Drawable, rt.Animation)

    for _, effect in pairs(effects) do
        out._effects[effect] = true
    end
    out:_update()
    return out
end)

--- @brief [internal] update held graphical object
function rt.Glyph:_update()

    local font = self._font[self._style]
    self._glyph = love.graphics.newText(font, {{self._color.r, self._color.g, self._color.b}, self._content})

    if not sizeof(self._character_widths) == 0 then
        self:_initialize_character_widths()
    end

    self:set_is_animated(sizeof(self._effects) > 0)

    if self._effects[rt.TextEffect.RAINBOW] == true then
        self._effects_data.rainbow = {}
        for i = 1, #self._content do
            self._effects_data.rainbow[i] = rt.RGBA(1, 1, 1, 1)
        end
    end

    if self._effects[rt.TextEffect.WAVE] == true or self._effects[rt.TextEffect.SHAKE] then
        self._effects_data.offsets = {}
        for i = 1, #self._content do
            self._effects_data.offsets[i] = rt.Vector2(0, 0)
        end
    end
end

--- @brief [internal] initialize data needed for `set_n_visible_characters`
function rt.Glyph:_initialize_character_widths()

    local clock = rt.Clock()
    self._character_widths = {}
    local offset = 0
    local n_chars = #self._content
    local font = self._font[self._style]
    for i = 1, n_chars  do

        local c = string.sub(self._content, i, i)
        local width;
        if i == 1 then
            width = font:getWidth(c)
        else
            local previous = string.sub(self._content, i - 1, i - 1)
            width = font:getWidth(c) + font:getKerning(previous, c)
        end

        offset = offset + width
        self._character_widths[i] = width
        self._character_offsets[i] = offset
    end
end

function rt.Glyph:_draw_outline(x, y)
    local offsets = {}
    for i = 1, rt.settings.glyph.outline_thickness do
        table.insert(offsets, i)
        table.insert(offsets, -i)
    end
    for _, x_offset in pairs(offsets) do
        for _, y_offset in pairs(offsets) do
            love.graphics.setColor(self._outline_color.r, self._outline_color.g, self._outline_color.b, self._outline_color.a)
            self:render(self._glyph, math.floor(x + x_offset), math.floor(y + y_offset))
        end
    end
end

--- @brief [internal] draw glyph with _is_animated = false
function rt.Glyph:_non_animated_draw()

    local old_r, old_g, old_b, old_a = love.graphics.getColor()

    local x, y = self:get_position()
    local w, h = self:get_size()

    if self._n_visible_chars >= #self._content then

        if self._is_outlined then self:_draw_outline(x, y) end

        love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)
        self:render(self._glyph, math.floor(x), math.floor(y))
    elseif self:get_n_visible_characters() > 0 then
        if sizeof(self._character_widths) == 0 then
            self:_initialize_character_widths()
        end

        local w = self._character_offsets[self._n_visible_chars]
        local _, h = self:get_size()
        love.graphics.setScissor(x, y, w, h)

        if self._is_outlined then self:_draw_outline(x, y) end

        love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)
        self:render(self._glyph, math.floor(x), math.floor(y))
        love.graphics.setScissor()
    end

    local font = self._font[self._style]
    local strikethrough_base = y + 0.5 * font:getHeight() + 0.5
    local underline_base = y + font:getBaseline() - 0.5 * font:getDescent()
    love.graphics.setLineWidth(1)

    if self._is_strikethrough then
        love.graphics.line(x, strikethrough_base, x + w, strikethrough_base)
    end

    if self._is_underlined then
        love.graphics.line(x, underline_base, x + w, underline_base)
    end

    love.graphics.setColor(old_r, old_g, old_b, old_a)
end

--- @brief [internal] draw glyph animation , much less performant
function rt.Glyph:_animated_draw()

    if sizeof(self._character_widths) == 0 then
        self:_initialize_character_widths()
    end

    local old_r, old_g, old_b, old_a = love.graphics.getColor()
    love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)
    love.graphics.push()

    local x, y = self:get_position()
    local _, h = self:get_size()

    local w = 0
    for i = 1, #self._content do

        if i > self._n_visible_chars then break end

        w = self._character_widths[i]
        local scissor = rt.AABB(x, y, w, h)
        local color = self._color

        if self._effects[rt.TextEffect.RAINBOW] == true then
            color = self._effects_data.rainbow[i]
        end

        local offset = rt.Vector2(0, 0)

        if self._effects[rt.TextEffect.WAVE] == true or self._effects[rt.TextEffect.SHAKE] == true then
            offset = self._effects_data.offsets[i]
        end

        love.graphics.setScissor(scissor.x + offset.x, scissor.y + offset.y, scissor.width, scissor.height)
        local pos_x, pos_y = self:get_position()
        if self._is_outlined then self:_draw_outline(pos_x + offset.x, pos_y + offset.y) end
        love.graphics.setColor(color.r, color.g, color.b, color.a)
        self:render(self._glyph, math.floor(pos_x + offset.x), math.floor(pos_y + offset.y))

        if self._is_strikethrough or self._is_underlined then
            local font = self._font[self._style]
            local strikethrough_base = pos_y + offset.y + 0.5 * font:getHeight() + 0.5
            local underline_base = pos_y + offset.y + font:getBaseline() - 0.5 * font:getDescent()
            local w = select(1, self:get_size())
            love.graphics.setLineWidth(1)

            if self._is_strikethrough then
                love.graphics.line(pos_x + offset.x, strikethrough_base, pos_x + offset.x + w, strikethrough_base)
            end

            if self._is_underlined then
                love.graphics.line(pos_x + offset.x, underline_base, pos_x + offset.x + w, underline_base)
            end
        end

        x = x + w
    end

    love.graphics.pop()
    love.graphics.setColor(old_r, old_g, old_b, old_a)
    love.graphics.setScissor()
end

--- @overload rt.Drawable.draw
function rt.Glyph:draw()

    if not self:get_is_visible() then return end

    if self:get_is_animated() then
        self:_animated_draw()
    else
        self:_non_animated_draw()
    end
end

--- @overload rt.Animation.update
function rt.Glyph:update(delta)
    self._elapsed_time = self._elapsed_time + delta
    for i = 1, #self._content do

        local x_offset = 0
        local y_offset = 0
        local use_offset = false

        if self._effects[rt.TextEffect.RAINBOW] then
            self._effects_data.rainbow[i] = rt.hsva_to_rgba(rt.HSVA(math.fmod((i / rt.settings.glyph.rainbow_width) + self._elapsed_time, 1), 1, 1, 1))
            local col = self._effects_data.rainbow[i]
        end

        if self._effects[rt.TextEffect.WAVE] == true then
            y_offset = y_offset + rt.settings.glyph.wave_function((self._elapsed_time / rt.settings.glyph.wave_speed) + i) * rt.settings.glyph.wave_offset
            use_offset = true
        end

        if self._effects[rt.TextEffect.SHAKE] == true then
            local i_offset = math.round(self._elapsed_time / (1 / rt.settings.glyph.shake_period))
            x_offset = x_offset + rt.rand(i + i_offset) * rt.settings.glyph.shake_offset
            y_offset = y_offset + rt.rand(i + i_offset + 4294967297) * rt.settings.glyph.shake_offset -- + 2^32+1
            use_offset = true
        end

        if use_offset then
            self._effects_data.offsets[i] = rt.Vector2(x_offset, y_offset)
        end
    end
end

--- @brief set font style
--- @param style rt.FontStyle
function rt.Glyph:set_style(style)
    self._style = style
    self:_update()
end

--- @brief get font style
--- @return rt.FontStyle
function rt.Glyph:get_style()
    return self._style
end

--- @brief set font color
--- @param color rt.RGBA
function rt.Glyph:set_color(color)

    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end

    self._color = color
    self:_update()
end

--- @brief get color
--- @return rt.RGBA
function rt.Glyph:get_color(color)
    return self._color
end

--- @brief measure text size
--- @return (Number, Number)
function rt.Glyph:get_size()

    return self._glyph:getDimensions()
end

--- @brief access content as string
--- @return String
function rt.Glyph:get_content()

    return self._content
end

--- @brief get number of characters of content
--- @return Number
function rt.Glyph:get_n_characters()

    return #self._content
end

--- @brief set top left position
--- @param x Number
--- @param y Number
function rt.Glyph:set_position(x, y)

    self._position_x = math.round(x)
    self._position_y = math.round(y)
end

--- @brief get top left position
--- @return (Number, Number)
function rt.Glyph:get_position()

    return self._position_x, self._position_y
end

--- @brief set number of visible characters, used for text scrolling
--- @param n Number
function rt.Glyph:set_n_visible_characters(n)


    n = clamp(n, 0, self:get_n_characters())
    self._n_visible_chars = n

    if sizeof(self._character_widths) == 0 then
        self:_initialize_character_widths()
    end
end

--- @brief get number of visible characters
--- @return Number
function rt.Glyph:get_n_visible_characters()

    return clamp(self._n_visible_chars, 0, self:get_n_characters())
end

--- @brief [internal] test glyph
function rt.test.glyph()
    error("TODO")
end

