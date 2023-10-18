--- @class rt.Glyph
rt.Glyph = meta.new_type("Glyph", function(font, content, font_style, color, wrap_width)

    meta.assert_isa(font, rt.Font)
    meta.assert_string(content)

    if meta.is_nil(font_style) then font_style = rt.FontStyle.REGULAR end
    if meta.is_nil(color) then color = rt.RGBA(1, 1, 1, 1) end
    if meta.is_nil(wrap_width) then wrap_width = POSITIVE_INFINITY end

    meta.assert_enum(font_style, rt.FontStyle)
    rt.assert_rgba(color)
    meta.assert_number(wrap_width)

    local out = meta.new(rt.Glyph, {
        _font = font,
        _content = content,
        _color = color,
        _style = font_style,
        _text = {},
        _position_x = 0,
        _position_y = 0,
        _n_visible_chars = POSITIVE_INFINITY,
        _glyph_offsets = {}
    }, rt.Drawable)
    out:_update()
    return out
end)

--- @brief [internal] update held graphical object
function rt.Glyph:_update()
    meta.assert_isa(self, rt.Glyph)
    local font = self._font[self._style]
    self._text = love.graphics.newText(font, {{self._color.r, self._color.g, self._color.b}, self._content})

    if not sizeof(self._glyph_offsets) == 0 then
        self:_initialize_glyph_offsets()
    end
end

--- @brief [internal] initialize data needed for `set_n_visible_characters`
function rt.Glyph:_initialize_glyph_offsets()

    local clock = rt.Clock()
    local now = rt.Cloc
    self._glyph_offsets = {}
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

        self._glyph_offsets[i] = offset
        offset = offset + width
    end
end

--- @brief draw glyph
function rt.Glyph:draw()
    meta.assert_isa(self, rt.Glyph)

    if not self:get_is_visible() or #self._content == 0 then return end

    local old_r, old_g, old_b, old_a = love.graphics.getColor()
    love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)
    love.graphics.push()

    local x, y = self:get_position()

    if self._n_visible_chars > #self._content then
        self:render(self._text, x, y)
    elseif self:get_n_visible_characters() > 0 then

        if sizeof(self._glyph_offsets) == 0 then
            self:_initialize_glyph_offsets()
        end

        local _, h = self:get_size()
        local w = self._glyph_offsets[self:get_n_visible_characters()]
        love.graphics.setScissor(x, y, w, h)
        self:render(self._text, x, y)
        love.graphics.setScissor()
    end

    love.graphics.pop()
    love.graphics.setColor(old_r, old_g, old_b, old_a)
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
    return self._text:getDimensions()
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
function rt.Glyph:set_n_visible_characters(x)
    meta.assert_isa(self, rt.Glyph)
    meta.assert_number(x)
    x = clamp(x, 0, self:get_n_characters())
    self._n_visible_chars = x
    if x < self:get_n_characters() and sizeof(self._glyph_offsets) == 0 then
        self:_initialize_glyph_offsets()
    end
end

--- @brief
function rt.Glyph:get_n_visible_characters()
    meta.assert_isa(self, rt.Glyph)
    return clamp(self._n_visible_chars, 0, self:get_n_characters())
end
