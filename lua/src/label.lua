--- @class rt.Font
rt.Font = meta.new_type("Font", function(regular_path, bold_path, italic_path, bold_italic_path)

    meta.assert_string(regular_path)

    local out = meta.new(rt.Font, {
        _regular_path = regular_path,
        _italic_path = regular_path,
        _bold_path = regular_path,
        _bold_italic_path = regular_path,
        _size = rt.Font.DEFAULT_SIZE
    })

    if not meta.is_nil(bold_path) then
        meta.assert_string(bold_path)
        out._bold_path = bold_path
    end

    if not meta.is_nil(italic_path) then
        meta.assert_string(italic_path)
        out._italic_path = italic_path
    end

    if not meta.is_nil(bold_italic_path) then
        meta.assert_string(bold_italic_path)
        out._bold_italic_path = bold_italic_path
    end

    out:_update()
    return out
end)

rt.Font.DEFAULT_SIZE = 14
rt.Font.DEFAULT = {}

--- @class rt.FontStyle
rt.FontStyle = meta.new_enum({
    REGULAR = "FONT_STYLE_REGULAR",
    ITALIC = "FONT_STYLE_ITALIC",
    BOLD = "FONT_STYLE_BOLD",
    BOLD_ITALIC = "FONT_STYLE_BOLD_ITALIC"
})

rt.Font[rt.FontStyle.REGULAR] = love.graphics.getFont()
rt.Font[rt.FontStyle.BOLD] = love.graphics.getFont()
rt.Font[rt.FontStyle.ITALIC] = love.graphics.getFont()
rt.Font[rt.FontStyle.BOLD_ITALIC] = love.graphics.getFont()

--- @brief [internal] update held fonts
function rt.Font:_update()
    meta.assert_isa(self, rt.Font)
    self[rt.FontStyle.REGULAR] = love.graphics.newFont(self._regular_path, self._size)
    self[rt.FontStyle.BOLD] = love.graphics.newFont(self._bold_path, self._size)
    self[rt.FontStyle.ITALIC] = love.graphics.newFont(self._italic_path, self._size)
    self[rt.FontStyle.BOLD_ITALIC] = love.graphics.newFont(self._bold_italic_path, self._size)
end

--- @brief [internal] load font form a google fonts folder
function rt.load_font(name, path)
    local regular = path .. "/" .. name .. "-Regular.ttf"
    local bold = path .. "/" .. name .. "-Bold.ttf"
    local italic = path .. "/" .. name .. "-Italic.ttf"
    local bold_italic = path .. "/" .. name .. "-BoldItalic.ttf"
    return rt.Font(regular, bold, italic, bold_italic)
end

--- @brief set font size, in px
--- @param px Number
function rt.Font:set_size(px)
    meta.assert_isa(self, rt.Font)
    self._size = px
    self:_update()
end

--- @brief get font size, in px
--- @return Number
function rt.Font:get_size()
    meta.assert_isa(self, rt.Font)
    return self._size
end

--- @class Glyph
rt.Glyph = meta.new_type("Glyph", function(font, content, font_style, color)

    if meta.is_nil(font_style) then font_style = rt.FontStyle.REGULAR end
    if meta.is_nil(color) then color = rt.RGBA(1, 1, 1, 1) end

    meta.assert_isa(font, rt.Font)
    meta.assert_enum(font_style, rt.FontStyle)
    rt.assert_rgba(color)

    local out = meta.new(rt.Glyph, {
        _font = font,
        _content = content,
        _color = color,
        _style = font_style,
        _text = {}
    }, rt.Drawable)
    out:_update()
    return out
end)

--- @brief [internal] update held graphical object
function rt.Glyph:_update()
    meta.assert_isa(self, rt.Glyph)
    local font = self._font[self._style]
    self._text = love.graphics.newText(font, {{self._color.r, self._color.g, self._color.b}, self._content})
end

--- @brief draw glyph
function rt.Glyph:draw()
    meta.assert_isa(self, rt.Glyph)
    rt.Drawable._draw(self, self._text)
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
    else
        rt.assert_rgba(color)
    end

    self._color = color
    self:_update()
end

--- @brief get color
--- @return rt.RGBA
function rt.Glyph:get_color(color)
    meta.assert_isa(self, rt.Glyph)
    return self._color
end
