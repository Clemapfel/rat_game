--- @class rt.TextEffect
rt.TextEffect = meta.new_enum({
    NONE = "TEXT_EFFECT_NONE",
    SHAKE = "TEXT_EFFECT_SHAKE",
    WAVE = "TEXT_EFFECT_WAVE",
    RAINBOW = "TEXT_EFFECT_RAINBOW"
})

--- @class rt.Glyph
rt.Glyph = meta.new_type("Glyph", function(font, content, font_style, color, effects, wrap_width)

    meta.assert_isa(font, rt.Font)
    meta.assert_string(content)

    if meta.is_nil(font_style) then font_style = rt.FontStyle.REGULAR end
    if meta.is_nil(color) then color = rt.RGBA(1, 1, 1, 1) end
    if meta.is_nil(effects) then effects = {} end
    if meta.is_nil(wrap_width) then wrap_width = POSITIVE_INFINITY end

    meta.assert_enum(font_style, rt.FontStyle)
    rt.assert_rgba(color)
    meta.assert_number(wrap_width)
    meta.assert_table(effects)

    local out = meta.new(rt.Glyph, {
        _font = font,
        _content = content,
        _color = color,
        _style = font_style,
        _effects = {},
        _is_animated = false,
        _elapsed_time = 0,
        _animation_offset = 0,
        _glyph = {},
        _position_x = 0,
        _position_y = 0,
        _n_visible_chars = POSITIVE_INFINITY,
        _character_widths = {},
        _character_offsets = {}
    }, rt.Drawable)

    for _, effect in pairs(effects) do
       out._effects[effect] = true
    end

    out:_update()
    return out
end)

--- @brief [internal] update held graphical object
function rt.Glyph:_update()
    meta.assert_isa(self, rt.Glyph)
    local font = self._font[self._style]
    self._glyph = love.graphics.newText(font, {{self._color.r, self._color.g, self._color.b}, self._content})

    if not sizeof(self._character_widths) == 0 then
        self:_initialize_character_widths()
    end
end

--- @brief [internal] initialize data needed for `set_n_visible_characters`
function rt.Glyph:_initialize_character_widths()

    local clock = rt.Clock()
    local now = rt.Cloc
    self._character_widths = {}
    local offset = 0
    local n_chars = #self._content
    for i = 1, n_chars  do

        local c = string.sub(self._content, i, i)
        local width;
        if i == 1 then
            width = self._font[rt.FontStyle.REGULAR]:getWidth(c)
        else
            local previous = string.sub(self._content, i - 1, i - 1)
            width = self._font[rt.FontStyle.REGULAR]:getWidth(c) + self._font[rt.FontStyle.REGULAR]:getKerning(previous, c)
        end

        offset = offset + width
        self._character_widths[i] = width
        self._character_offsets[i] = offset
    end
end

--- @brief [internal] draw glyph with _is_animated = false
function rt.Glyph:_non_animated_draw()

    local old_r, old_g, old_b, old_a = love.graphics.getColor()
    love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)
    love.graphics.push()

    local x, y = self:get_position()
    local w = self._character_offsets[self._n_visible_chars]

    if self._n_visible_chars >= #self._content then
        self:render(self._glyph, x, y)
    elseif self:get_n_visible_characters() > 0 then
        if sizeof(self._character_widths) == 0 then
            self:_initialize_character_widths()
        end

        local _, h = self:get_size()
        love.graphics.setScissor(x, y, w, h)
        self:render(self._glyph, x, y)
        love.graphics.setScissor()
    end

    love.graphics.pop()
    love.graphics.setColor(old_r, old_g, old_b, old_a)
end

rt.SETTINGS.glyph = {}
rt.SETTINGS.glyph.rainbow_width = 15 -- n characters
rt.SETTINGS.glyph.shake_intensity = 10 -- in px

rt.SETTINGS.glyph.wave_period = 5
rt.SETTINGS.glyph.wave_function = function(x)
    return math.sin((x * 4 * math.pi) / (2 * rt.SETTINGS.glyph.wave_period))
end

--- @brief update animated glyph
function rt.Glyph:update(delta, animation_offset)
    meta.assert_isa(self, rt.Glyph)
    meta.assert_number(delta)

    if not meta.is_nil(animation_offset) then
        meta.assert_number(animation_offset)
        self._animation_offset = animation_offset
    end

    self._elapsed_time = self._elapsed_time + delta
end

--- @brief [internal] draw glyph with _is_animated = true, much less performant
function rt.Glyph:_animated_draw()

    if sizeof(self._character_widths) == 0 then
        self:_initialize_character_widths()
    end

    local old_r, old_g, old_b, old_a = love.graphics.getColor()
    love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)
    love.graphics.push()

    local x, y = self:get_position()
    local _, h = self:get_size()

    -- todo
    if meta.is_nil(rt.Glyph.DEBUG_COLORS) then
        rt.Glyph.DEBUG_COLORS = {}
        for i = 1, #self._content do
            local hue = i / #self._content
            table.insert(rt.Glyph.DEBUG_COLORS, rt.hsva_to_rgba(rt.HSVA(hue, 1, 1, 1)))
        end
    end
    -- todo

    local w = 0
    for i = 1, #self._content do
        w = self._character_widths[i]
        local scissor = rt.AABB(x, y, w, h)
        love.graphics.setScissor(scissor.x, scissor.y, scissor.width, scissor.height)
        local color = self._color

        if self._effects[rt.TextEffect.RAINBOW] == true then
            color = rt.hsva_to_rgba(rt.HSVA(math.fmod((i / rt.SETTINGS.glyph.rainbow_width) + self._elapsed_time, 1), 1, 1, 1))
        end

        love.graphics.setColor(color.r, color.g, color.b, color.a)
        self:render(self._glyph, self:get_position())
        love.graphics.setScissor()
        x = x + w
    end

    love.graphics.pop()
    love.graphics.setColor(old_r, old_g, old_b, old_a)
end

--- @overload rt.Drawable.draw
function rt.Glyph:draw()
    meta.assert_isa(self, rt.Glyph)
    if not self:get_is_visible() then return end

    if self._is_animated then
        self:_animated_draw()
    else
        self:_non_animated_draw()
    end
end

--- @brief set font style
--- @param style rt.FontStyle
function rt.Glyph:set_style(style)
    meta.assert_isa(self, rt.Glyph)
    meta.assert_enum(style, rt.FontStyle)
    self._style = style
    self:_update()
end

--- @brief get font style
--- @param style rt.FontStyle
function rt.Glyph:get_style()
    meta.assert_isa(self, rt.Glyph)
    meta.assert_enum(style, rt.FontStyle)
    return self._style
end

--- @brief set font color
--- @param color rt.RGBA
function rt.Glyph:set_color(color)
    meta.assert_isa(self, rt.Glyph)

    if rt.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end
    rt.assert_rgba(color)

    self._color = color
    self:_update()
end

--- @brief get color
--- @return rt.RGBA
function rt.Glyph:get_color(color)
    meta.assert_isa(self, rt.Glyph)
    return self._color
end

--- @brief measure text size
function rt.Glyph:get_size()
    meta.assert_isa(self, rt.Glyph)
    return self._glyph:getDimensions()
end

--- @brief access content as string
function rt.Glyph:get_content()
    meta.assert_isa(self, rt.Glyph)
    return self._content
end

--- @brief
function rt.Glyph:get_n_characters()
    meta.assert_isa(self, rt.Glyph)
    return #self._content
end

--- @brief
function rt.Glyph:set_position(x, y)
    meta.assert_isa(self, rt.Glyph)
    self._position_x = math.round(x)
    self._position_y = math.round(y)
end

--- @brief
function rt.Glyph:get_position()
    meta.assert_isa(self, rt.Glyph)
    return self._position_x, self._position_y
end

--- @brief
function rt.Glyph:set_n_visible_characters(n)
    meta.assert_isa(self, rt.Glyph)
    meta.assert_number(n)
    n = clamp(n, 0, self:get_n_characters())
    self._n_visible_chars = n

    if sizeof(self._character_widths) == 0 then
        self:_initialize_character_widths()
    end
end

--- @brief
function rt.Glyph:get_n_visible_characters()
    meta.assert_isa(self, rt.Glyph)
    return clamp(self._n_visible_chars, 0, self:get_n_characters())
end

--- @brief
function rt.Glyph:get_is_animated()
    meta.assert_isa(self, rt.Glyph)
    return self._is_animated
end

--- @brief
function rt.Glyph:set_is_animated()
    meta.assert_isa(self, rt.Glyph)
    self._is_animated = true
end