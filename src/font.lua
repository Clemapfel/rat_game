--- @class rt.Font
rt.Font = meta.new_type("Font", function(regular_path, bold_path, italic_path, bold_italic_path)

    meta.assert_string(regular_path)

    local out = meta.new(rt.Font, {
        _regular_path = regular_path,
        _italic_path = regular_path,
        _bold_path = regular_path,
        _bold_italic_path = regular_path,
        _size = rt.Font.DEFAULT_SIZE,
        _regular_rasterizer = {},
        _italic_rasterizer = {},
        _bold_rasterizer = {},
        _bold_italic_rasterizer = {}
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

    self._regular_rasterizer = love.font.newRasterizer(self._regular_path, self._size)
    self._bold_rasterizer = love.font.newRasterizer(self._bold_path, self._size)
    self._italic_rasterizer = love.font.newRasterizer(self._italic_path, self._size)
    self._bold_italic_rasterizer = love.font.newRasterizer(self._bold_italic_path, self._size)
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

--- @brief
function rt.Font:get_regular()
    meta.assert_isa(self, rt.Font)
    return self[rt.FontStyle.REGULAR]
end

--- @brief
function rt.Font:get_bold()
    meta.assert_isa(self, rt.Font)
    return self[rt.FontStyle.BOLD]
end

--- @brief
function rt.Font:get_italic()
    meta.assert_isa(self, rt.Font)
    return self[rt.FontStyle.ITALIC]
end

--- @brief
function rt.Font:get_bold_italic()
    meta.assert_isa(self, rt.Font)
    return self[rt.FontStyle.BOLD_ITALIC]
end