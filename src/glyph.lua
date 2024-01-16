rt.settings.glyph = {
    default_background_color = rt.RGBA(0, 0, 0, 1),
    default_outline_color = rt.RGBA(0, 0, 0, 1),
    outline_thickness = 1,
    outline_render_texture_padding = 3,
    rainbow_width = 10,    -- n characters per cycle
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

    look = which(look, {})
    meta.assert_table(look)
    local font_style = look.font_style
    local color = look.color
    local is_underlined = look.is_underlined
    local is_strikethrough = look.is_strikethrough
    local is_outlined = look.is_outlined
    local outline_color = look.outline_color
    local effects = look.effects
    local wrap_width = look.wrap_width

    if meta.is_nil(font_style) then font_style = rt.FontStyle.REGULAR end
    if meta.is_nil(color) then color = rt.RGBA(1, 1, 1, 1) end
    if meta.is_nil(effects) then effects = {} end
    if meta.is_nil(wrap_width) then wrap_width = POSITIVE_INFINITY end
    if meta.is_nil(is_underlined) then is_underlined = false end
    if meta.is_nil(is_strikethrough) then is_strikethrough = false end
    if meta.is_nil(is_outlined) then is_outlined = false end
    if meta.is_nil(outline_color) then outline_color = rt.settings.glyph.default_outline_color end

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
        _glyph = {}, -- love.Text
        _position_x = 0,
        _position_y = 0,
        _n_visible_chars = POSITIVE_INFINITY,
        _character_widths = {},
        _character_offsets = {},
        _current_width = 0,
        _effects_data = {},
        _outline_render_texture = {} -- rt.RenderTexture
    }, rt.Drawable, rt.Animation)

    for _, effect in pairs(effects) do
        out._effects[effect] = true
    end
    out:_update()
    return out
end)

rt.Glyph._outline_shader = rt.Shader("assets/shaders/glyph_outline.glsl")
rt.Glyph._outline_color = rt.RGBA(0, 0, 0, 1)
rt.Glyph._rainbow_shader = rt.Shader("assets/shaders/glyph_rainbow.glsl")

--- @brief [internal]
function rt.Glyph:_update_outline()
    if self._is_outlined == true then
        local w, h = self._current_width, self._glyph:getHeight()
        local offset = rt.settings.glyph.outline_render_texture_padding;
        w, h = w + 2 * offset, h + 2 * offset

        if self._effects[rt.TextEffect.WAVE] then
            w = w + 2 * rt.settings.glyph.wave_offset
            h = h + 2 * rt.settings.glyph.wave_offset
            offset = offset + rt.settings.glyph.wave_offset
        end

        if self._effects[rt.TextEffect.SHAKE] then
            w = w + 2 * rt.settings.glyph.shake_offset
            h = h + 2 * rt.settings.glyph.shake_offset
            offset = offset + rt.settings.glyph.shake_offset
        end

        if not meta.isa(self._outline_render_texture, rt.RenderTexture) or self._outline_render_texture:get_width() ~= w or self._outline_render_texture:get_height() ~= h then
            self._outline_render_texture = rt.RenderTexture(w, h)
        end

        love.graphics.push()
        love.graphics.reset()

        self._outline_render_texture:bind_as_render_target()
        love.graphics.clear(0, 0, 0, 0)
        self:render(self._glyph, offset, offset)
        self._outline_render_texture:unbind_as_render_target()

        love.graphics.pop()
    end
end

--- @brief [internal] update held graphical object
function rt.Glyph:_update()

    local font = self:_get_font()
    self._glyph = love.graphics.newText(font, {{self._color.r, self._color.g, self._color.b}, self._content})

    if not sizeof(self._character_widths) == 0 then
        self:_initialize_character_widths()
    end

    self:set_is_animated(sizeof(self._effects) > 0)

    if self._effects[rt.TextEffect.RAINBOW] == true then
        self._effects_data.rainbow = {}
        for i = 1, utf8.len(self._content) do
            self._effects_data.rainbow[i] = rt.RGBA(1, 1, 1, 1)
        end
    end

    if self._effects[rt.TextEffect.WAVE] == true or self._effects[rt.TextEffect.SHAKE] then
        self._effects_data.offsets = {}
        for i = 1, utf8.len(self._content) do
            self._effects_data.offsets[i] = rt.Vector2(0, 0)
        end
    end

    self._current_width = self._glyph:getWidth()
    self:_update_outline()
end

--- @brief [internal] initialize data needed for `set_n_visible_characters`
function rt.Glyph:_initialize_character_widths()

    self._character_widths = {}
    local offset = 0
    local n_chars = utf8.len(self._content)
    local font = self:_get_font()
    for i = 1, n_chars  do
        local c = utf8.sub(self._content, i, i)
        local width;
        if i == 1 then
            width = font:getWidth(c)
        else
            local previous = utf8.sub(self._content, i - 1, i - 1)
            width = font:getWidth(c) + font:getKerning(previous, c)
        end

        offset = offset + width
        self._character_widths[i] = width
        self._character_offsets[i] = offset
    end
end

--- @brief [internal]
function rt.Glyph:_draw_outline(x, y)

    local offset = rt.settings.glyph.outline_render_texture_padding;

    self._outline_shader:bind()
    self._outline_shader:send("_texture_resolution", {self._outline_render_texture:get_size()})
    self:render(self._outline_render_texture._native, x - offset, y - offset)
    self._outline_shader:unbind()
end

--- @brief [internal] draw glyph with _is_animated = false
function rt.Glyph:draw()
    local x, y = self:get_position()
    local w, h = self:get_size()

    if sizeof(self._character_widths) == 0 then
        self:_initialize_character_widths()
    end

    local w = self._character_offsets[self._n_visible_chars]
    local _, h = self:get_size()

    if self._is_outlined then self:_draw_outline(x, y) end

    if self._effects[rt.TextEffect.RAINBOW] then
        self._rainbow_shader:send("_text_color_rgba", {self._color.r, self._color.g, self._color.b, self._color.a})
        self._rainbow_shader:send("_time", self._elapsed_time)
        self._rainbow_shader:send("_rainbow_width", rt.settings.glyph.rainbow_width)
        self._rainbow_shader:bind()
    end

    love.graphics.setColor(self._color.r, self._color.g, self._color.b, self._color.a)
    self:render(self._glyph, math.floor(x), math.floor(y))

    if self._effects[rt.TextEffect.RAINBOW] then
        self._rainbow_shader:unbind()
    end

    local font = self:_get_font()
    local strikethrough_base = y + 0.5 * font:getHeight() + 0.5
    local underline_base = y + font:getBaseline() - 0.5 * font:getDescent()
    love.graphics.setLineWidth(1)

    if self._is_strikethrough then
        love.graphics.line(x, strikethrough_base, x + w, strikethrough_base)
    end

    if self._is_underlined then
        love.graphics.line(x, underline_base, x + w, underline_base)
    end
end

--- @overload rt.Animation.update
function rt.Glyph:update(delta)

    self._elapsed_time = self._elapsed_time + delta

    self._glyph = love.graphics.newText(self:_get_font(), {{self._color.r, self._color.g, self._color.b}, ""})
    local font = self:_get_font()
    local width = 0
    for i = 1, math.min(utf8.len(self._content), self._n_visible_chars) do

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

        local current = utf8.sub(self._content, i, i)
        local kerning = 0
        if i > 1 then
            local previous = utf8.sub(self._content, i - 1, i - 1)
            kerning = font:getKerning(previous, current)
        end

        self._glyph:add(
            utf8.sub(self._content, i, i),
            width + kerning + x_offset, y_offset,
            0,     -- rotation (rad)
            1, 1,  -- scale
            0, 0,  -- origin offset
            0, 0   -- shear
        )

        width = width + font:getWidth(current) + kerning
    end

    self._current_width = width
    self:_update_outline()
end

--- @brief set font style
--- @param style rt.FontStyle
function rt.Glyph:set_style(style)
    if self._style == style then return end
    self._style = style
    self:_update()
end

--- @brief set content
function rt.Glyph:set_text(text)
    if self._content == text then return end
    self._content = text
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

    if self._color == color then return end
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
    return utf8.len(self._content)
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
    if n ~= self._n_visible_chars then
        n = clamp(n, 0, self:get_n_characters())
        self._n_visible_chars = n
        self._glyph = love.graphics.newText(self:_get_font(), {{self._color.r, self._color.g, self._color.b}, utf8.sub(self._content, 1, n)})
        self:_update_outline()
    end
end

--- @brief get number of visible characters
--- @return Number
function rt.Glyph:get_n_visible_characters()
    return clamp(self._n_visible_chars, 0, self:get_n_characters())
end

--- @brief [internal]
function rt.Glyph:_get_font()
    return self._font[self._style]
end

--- @brief [internal] test glyph
function rt.test.glyph()
    error("TODO")
end