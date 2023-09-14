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

--- @brief measure text size
function rt.Glyph:get_width()
    return self._text:getWidth()
end

--- @class Label
rt.Label = meta.new_type("Label", function(formatted_text)
    local out = meta.new(rt.Label, {
        _glyphs = {}
    }, rt.Drawable)
    out:parse_from(formatted_text)
    return out
end)

rt.Label.BOLD_TAG = "b"       -- <b>example</b>
rt.Label.ITALIC_TAG = "i"     -- <i>example</i>
rt.Label.COLOR_TAG = "color"  -- <color=hotpink>example</color>

function rt.Label:parse_from(text)

    local glyphs = self._glyphs
    local error_reason = ""

    local bold = false
    local italic = false
    local color = false

    local current_glyph = ""
    local x = 0   -- x-position
    local y = 0   -- y-position
    local i = 1   -- character index
    local s = ""  -- current character

    local function step()
        i = i + 1
        s = string.sub(text, i, i)
    end

    local function assert_tag_close()
        if s ~= ">" then
            error_reason = "Expected `<`, got `" .. s .. "`"
            return false
        end
        return true
    end

    while i < #text do
        if s == "<" then  -- open tag

            step()
            if i > #text then
                goto error
            end

            if s == "b" then -- open bold
                if bold then
                    error_reason = "bold region is already open"
                    goto error
                end

                bold = true
                step()
                if not assert_tag_close() then goto error end
            elseif s == "i" then -- open italic
                if italic then
                    error_reason = "italic region is already open"
                    goto error
                end
                italic = true
                step()
                if not assert_tag_close() then goto error end
            elseif s == "c" then -- open color
                -- TODO color
                step()
                if not assert_tag_close() then goto error end
            elseif s == "/" then -- close tag
                step()
                if s == "b" then -- close bold
                    if not bold then
                        error_reason = "trying to close bold region, but it is not open"
                        goto error
                    end
                    bold = false
                    step()
                    if not assert_tag_close() then goto error end
                    goto next
                elseif s == "i" then
                    if not italic then
                        error_reason = "trying to close italic region, but it is not open"
                        goto error
                    end
                    italic = false
                    step()
                    if not assert_tag_close() then goto error end
                    goto next
                elseif s == "c" then
                    -- TODO: color
                    step()
                    if not assert_tag_close() then goto error end
                    goto next
                else
                    error_reason = "Unexpcted control character: `" .. s .. "`"
                    goto error
                end
            else
                error_reason = "Unexpcted control character: `" .. s .. "`"
                goto error
            end
        elseif s == ">" then
            error_reason  = "Unexpected control region"
            goto error
        else
            local style = rt.FontStyle.REGULAR
            if bold and italic then
                style = rt.FontStyle.BOLD_ITALIC
            elseif bold then
                style = rt.FontStyle.BOLD
            elseif italic then
                style = rt.FontStyle.ITALIC
            end

            table.insert(glyphs, rt.Glyph(rt.Font.DEFAULT, s, style))
        end
        step()
        ::next::
    end

    ::error::
    error("[rt] In Label.parse_from: At position `" .. tostring(i) .. "`: " .. error_reason)
end

function rt.Label:draw()
    for _, glyph in ipairs(self._glyphs) do
        glyph:draw()
    end
end

