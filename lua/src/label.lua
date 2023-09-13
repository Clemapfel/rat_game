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

rt.FontStyle = meta.new_enum({
    REGULAR = "regular",
    ITALIC = "italic",
    BOLD = "bold",
    BOLD_ITALIC = "bold_italic"
})

rt.Font[rt.FontStyle.REGULAR] = love.graphics.getFont()
rt.Font[rt.FontStyle.BOLD] = love.graphics.getFont()
rt.Font[rt.FontStyle.ITALIC] = love.graphics.getFont()
rt.Font[rt.FontStyle.BOLD_ITALIC] = love.graphics.getFont()

--- @brief [internal]
function rt.Font:_update()
    meta.assert_isa(self, rt.Font)
    self[rt.FontStyle.REGULAR] = love.graphics.newFont(self._regular_path, self._size)
    self[rt.FontStyle.BOLD] = love.graphics.newFont(self._italic_path, self._size)
    self[rt.FontStyle.ITALIC] = love.graphics.newFont(self._bold_path, self._size)
    self[rt.FontStyle.BOLD_ITALIC] = love.graphics.newFont(self._bold_italic_path, self._size)
end

--- @brief [internal]
function rt.load_font(name, path)
    local regular = path .. "/" .. name .. "-Medium.ttf"
    local bold = path .. "/" .. name .. "-Bold.ttf"
    local italic = path .. "/" .. name .. "-Italic.ttf"
    local bold_italic = path .. "/" .. name .. "-BoldItalic.ttf"
    return rt.Font(regular, bold, italic, bold_italic)
end

--- @brief set font size, in px
--- @param px Number
function rt.Font.set_size(px)
    meta.assert_isa(self, rt.Font)
    self._size = px
    self:_update()
end

--- @brief get font size, in px
--- @return Number
function rt.Font.get_size()
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
    })
    out:_update()
    return out
end)

--- @brief [internal]
function rt.Glyph:_update()
    meta.assert_isa(self, rt.Glyph)

    local font = self._font[self._style]
    self._text = love.graphics.newText(font, {{self._color.r, self._color.g, self._color.b}, self._content})
    println(serialize(self))
end

--- @brief
function rt.Glyph:draw()
    meta.assert_isa(self, rt.Glyph)
    love.graphics.draw(self._text)
end
