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
    if #self._glyph_offsets > 0 then
        self:_initialize_glyph_offsets()
    end
end

--- @brief [internal] initialize data needed for `set_n_visible_characters`
function rt.Glyph:_initialize_glyph_offsets()

    local clock = rt.Clock()
    local now = rt.Cloc
    self._glyph_offsets = {}
    local offset = 0
    for i = 1, #self._content do
        local x = string.sub(self._content, 1, i)
        --self._glyph_offsets[i] = #x --self._font[rt.FontStyle.REGULAR]:getWrap(, POSITIVE_INFINITY)
        local c = string.sub(self._content, i, i)
        local previous;
        if i == 1 then
            previous = " "
        else
            previous = string.sub(self._content, i - 1, i - 1)
        end

        local data, kerning, bearing, advance

        if self._style == rt.FontStyle.BOLD_ITALIC then
            data = self._font._bold_italic_rasterizer:getGlyphData(c)
            kerning = self._font[rt.FontStyle.BOLD_ITALIC]:getKerning(previous, c)
            advance = self._font._bold_italic_rasterizer:getAdvance()
        elseif self._style == rt.FontStyle.ITALIC then
            data = self._font._italic_rasterizer:getGlyphData(c)
            kerning = self._font[rt.FontStyle.ITALIC]:getKerning(previous, c)
            advance = self._font._italic_rasterizer:getAdvance()
        elseif self._style == rt.FontStyle.BOLD then
            data = self._font._bold_rasterizer:getGlyphData(c)
            kerning = self._font[rt.FontStyle.BOLD]:getKerning(previous, c)
            advance = self._font._bold_rasterizer:getAdvance()
        else
            data = self._font._regular_rasterizer:getGlyphData(c)
            kerning = self._font[rt.FontStyle.REGULAR]:getKerning(previous, c)
            advance = self._font._regular_rasterizer:getAdvance()
        end

        local width = data:getWidth()
        local bearing, _ = data:getBearing()

        println(previous, " ", c, " : ", width , " + ", bearing, " + ", kerning, " | ", advance)
        local new_width;
        if previous == "" then
            new_width = self._font[rt.FontStyle.REGULAR]:getWidth(c)
        else
            new_width = self._font[rt.FontStyle.REGULAR]:getWidth(c) + self._font[rt.FontStyle.REGULAR]:getKerning(previous, c)
        end

        self._glyph_offsets[i] = offset
        offset = offset + new_width
    end

    println(clock:restart():as_seconds())
end

--- @brief draw glyph
function rt.Glyph:draw()
    meta.assert_isa(self, rt.Glyph)

    if not self:get_is_visible() then return end

    local old_r, old_g, old_b, old_a = love.graphics.getColor()
    love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)

    local x, y = self:get_position()

    if self._n_visible_chars >= #self._content then
        self:render(self._text, x, y)
    elseif self:get_n_visible_characters() > 0 then
        local _, h = self:get_size()
        local w = self._glyph_offsets[self:get_n_visible_characters()]
        love.graphics.setScissor(x, y, w, h)
        self:render(self._text, x, y)
        love.graphics.setScissor()
    end

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
    self._position_x = x
    self._position_y = y
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


--[[
--- @class Label
rt.Label = meta.new_type("Label", function(formatted_text)
    local out = meta.new(rt.Label, {
        _glyphs = {},
        _raw = formatted_text
    }, rt.Drawable)
    out:parse_from(formatted_text)
    return out
end)

rt.Label.BOLD_TAG = "b"       -- <b>example</b>
rt.Label.ITALIC_TAG = "i"     -- <i>example</i>
rt.Label.COLOR_TAG = "color"  -- <color=hotpink>example</color>

--- @brief
function rt.Label:parse_from(text)
    self._raw = text
    local glyphs = self._glyphs
    local error_reason = ""
    local error_occurred = false

    local bold = false
    local italic = false
    local color = false
    local current_color = "white"

    local current_glyph = ""
    local x = 0   -- x-position
    local y = 0   -- y-position
    local i = 1   -- character index
    local s = string.sub(text, 1, 1)  -- current character

    local function step()
        i = i + 1
        s = string.sub(text, i, i)
    end

    local function push_glyph()
        if current_glyph == "" then return end

        ---println(current_glyph, " ", bold, " ", italic, " ", color)

        local style = rt.FontStyle.REGULAR
        if bold and italic then
            style = rt.FontStyle.BOLD_ITALIC
        elseif bold then
            style = rt.FontStyle.BOLD
        elseif italic then
            style = rt.FontStyle.ITALIC
        end

        if color then
            current_color = rt.RGBA(1, 0, 1, 1)
            println(current_color)
        else
            current_color = rt.RGBA(1, 1, 1, 1)
        end

        local to_push = rt.Glyph(rt.Font.DEFAULT, current_glyph, style, current_color)
        to_push:set_position(x, y)
        x = x + to_push:get_width()
        table.insert(glyphs, to_push)
        current_glyph = ""
    end

    while i < #text do
        if s == "<" then
            step()
            if s == "/" then
                step()
                if s == "b" then
                    if not bold then
                        error("attempting to close a bold reason, but none is open")
                    end
                    push_glyph()
                    bold = false
                    step()
                    if s ~= ">" then
                        error("Expected `>`, got `" .. s .. "`")
                    end
                    step()
                elseif s == "i" then
                    if not italic then
                        error("attempting to close an italic region, but none is open")
                    end
                    push_glyph()
                    italic = false
                    step()
                    if s ~= ">" then
                        error("Expected `>`, got `" .. s .. "`")
                    end
                    step()
                elseif s == "c" then
                    if not color then
                        error("attempting to close a color region, but none is open")
                    end

                    step()
                    local next = string.sub(text, i, i + #"olor>"-1)
                    if not (next == "olor>") then
                        error("unexpected `" .. next .. "` when closing color region")
                    end

                    push_glyph()
                    color = false
                    for i = 1, #"olor>" do
                        step()
                    end
                else
                    error("unrecognized flag: `" .. s .. "`")
                end
            elseif s == "b" then
                if bold then
                    error("attempting to open a bold region, but one is already open")
                end
                push_glyph()
                bold = true
                step()
                if s ~= ">" then
                    error("Expected `>`, got `" .. s .. "`")
                end
                step()
            elseif s == "i" then
                if italic then
                    error("attempting to open an italic region, but one is already open")
                end
                push_glyph()
                italic = true
                step()
                if s ~= ">" then
                   error("Expected `>`, got `" .. s .. "`")
                end
                step()
            elseif s == "c" then
                if color then
                    error("attempting to open a color region, but one is already open")
                end

                step()
                local next = string.sub(text, i, i + #"olor>"-1)
                if not (next == "olor>") then
                    error("unexpected `" .. next .. "` when opening color region")
                end
                push_glyph()
                color = true

                for i=1,#"olor>" do step() end
            else
                error("unrecognized flag: `" .. s .. "`")
            end
        else
            current_glyph = current_glyph .. s
            step()
        end
    end

    current_glyph = current_glyph .. s
    push_glyph()

    if bold then
        error("Reached end of text, but bold region is still open")
    end

    if italic then
        error("Reached end of text, but italic region is still open")
    end
end

function rt.Label:draw()
    for _, glyph in pairs(self._glyphs) do
        glyph:draw()
    end
end
]]--
