rt.settings.glyph = {
    default_background_color = rt.RGBA(0, 0, 0, 1),
    default_outline_color = rt.RGBA(0, 0, 0, 1),
    outline_thickness = 1,
    outline_render_texture_padding = 3,
    rainbow_width = 10,    -- n characters
    shake_offset = 1,      -- px
    shake_period = 10,     -- shakes per second
    wave_period = 10,      -- n chars
    wave_offset = 10,      -- px
    wave_speed = 0.2       -- cycles per second
}

--- @class rt.TextEffect
rt.TextEffect = meta.new_enum({
    NONE = "TEXT_EFFECT_NONE",
    SHAKE = "TEXT_EFFECT_SHAKE",
    WAVE = "TEXT_EFFECT_WAVE",
    RAINBOW = "TEXT_EFFECT_RAINBOW"
})

--[[ TODO
outline
outline color
rainbow
shake
wave
strikethrough
outline
]]--

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

    if meta.is_nil(font_style) then font_style = rt.FontStyle.REGULAR end
    if meta.is_nil(color) then color = rt.RGBA(1, 1, 1, 1) end
    if meta.is_nil(effects) then effects = {} end
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
        _effects = {},      -- Set<rt.TextEffect>
        _elapsed_time = 0,  -- seconds
        _glyph = {},        -- love.Text
        _position_x = 0,
        _position_y = 0,
        _n_visible_characters = utf8.len(content),

        _is_outlined = is_outlined,
        _outline_color = outline_color,
        _outline_render_texture = {}, -- rt.RenderTexture
        _outline_render_offset_x = 0,
        _outline_render_offset_y = 0,

        _underline = {},
        _strikethrough = {}
    }, rt.Drawable, rt.Animation)

    for _, effect in pairs(effects) do
        out._effects[effect] = true
    end
    out:_update()
    return out
end)

rt.Glyph._outline_shader = rt.Shader("assets/shaders/glyph_outline.glsl")
rt.Glyph._render_shader = rt.Shader("assets/shaders/glyph_render.glsl")

--- @brief [internal]
function rt.Glyph:_get_font()
    return self._font[self._style]
end

--- @brief update held object
function rt.Glyph:_update()
    self._glyph = love.graphics.newText(self:_get_font(), {{self._color.r, self._color.g, self._color.b}, self._content})
    self:set_is_animated(sizeof(self._effects) > 0)

    if self._is_outlined == true then
        local w, h = self:get_size()
        local x_offset = rt.settings.glyph.outline_render_texture_padding
        local y_offset = rt.settings.glyph.outline_render_texture_padding

        w, h = w + 2 * x_offset, h + 2 * y_offset

        if self._effects[rt.TextEffect.WAVE] then
            w = w + 2 * rt.settings.glyph.wave_offset
            h = h + 2 * rt.settings.glyph.wave_offset
            y_offset = y_offset + rt.settings.glyph.wave_offset
        end

        if self._effects[rt.TextEffect.SHAKE] then
            w = w + 2 * rt.settings.glyph.shake_offset
            h = h + 2 * rt.settings.glyph.shake_offset
            x_offset = x_offset + rt.settings.glyph.shake_offset
            y_offset = y_offset + rt.settings.glyph.shake_offset
        end

        if not meta.isa(self._outline_render_texture, rt.RenderTexture) or self._outline_render_texture:get_width() ~= w or self._outline_render_texture:get_height() ~= h then
            self._outline_render_texture = rt.RenderTexture(w, h)
        end

        self._outline_render_offset_x = x_offset
        self._outline_render_offset_y = y_offset
    end

    if self._is_underlined or self._is_strikethrough then
        local font = self:_get_font()
        local underline_y = font:getBaseline() - 0.5 * font:getDescent()
        local strikethrough_y = 0.5 * font:getHeight() + 0.5

        local underline_vertices = {}
        local strikethrough_vertices = {}

        local x = 0
        local previous_length = 0
        local text = ""
        for i = 1, self:get_n_characters() do
            text = text .. utf8.sub(self._content, i, i)
            local current_length = font:getWidth(text)
            local width = current_length - previous_length

            for p in range(x, underline_y) do
                table.insert(underline_vertices, p)
            end

            for p in range(x, strikethrough_y) do
                table.insert(strikethrough_vertices, p)
            end

            x = x + width
            previous_length = current_length
        end

        for p in range(x, underline_y) do
            table.insert(underline_vertices, p)
        end

        for p in range(x, strikethrough_y) do
            table.insert(strikethrough_vertices, p)
        end

        self._underline = underline_vertices
        self._strikethrough = strikethrough_vertices
    end
end

--- @brief [internal]
function rt.Glyph:_draw_underline(x, y)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.setLineWidth(3)
    love.graphics.line(self._underline)
    love.graphics.pop()
end

--- @brief [internal]
function rt.Glyph:_draw_strikethrough(x, y)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.setLineWidth(3)
    love.graphics.line(self._strikethrough)
    love.graphics.pop()
end

--- @overload
function rt.Glyph:draw()

    self._render_shader:send("_shake_active", self._effects[rt.TextEffect.SHAKE] == true)
    self._render_shader:send("_shake_offset", rt.settings.glyph.shake_offset)
    self._render_shader:send("_shake_period", rt.settings.glyph.shake_period)

    self._render_shader:send("_wave_active", self._effects[rt.TextEffect.WAVE] == true)
    self._render_shader:send("_wave_period", rt.settings.glyph.wave_period)
    self._render_shader:send("_wave_offset", rt.settings.glyph.wave_offset)
    self._render_shader:send("_wave_speed", rt.settings.glyph.wave_speed)

    self._render_shader:send("_rainbow_active", self._effects[rt.TextEffect.RAINBOW] == true)
    self._render_shader:send("_rainbow_width", rt.settings.glyph.rainbow_width)

    self._render_shader:send("_n_visible_characters", self._n_visible_characters)
    self._render_shader:send("_time", self._elapsed_time)

    function draw_glyph(x, y)
        self._render_shader:bind()
        self:render(self._glyph, math.floor(x), math.floor(y))

        local font = self:_get_font()
        local w = self._glyph:getWidth()

        if self._is_strikethrough then
            self:_draw_strikethrough(x, y)
        end

        if self._is_underlined then
            self:_draw_underline(x, y)
        end

        self._render_shader:unbind()
    end

    local x, y = self._position_x, self._position_y

    if self._is_outlined then
        -- paste glyph to render texture
        love.graphics.push()
        love.graphics.reset()

        self._outline_render_texture:bind_as_render_target()
        self._render_shader:bind()
        love.graphics.clear(0, 0, 0, 0)
        draw_glyph(self._outline_render_offset_x, self._outline_render_offset_y)
        self._outline_render_texture:unbind_as_render_target()

        love.graphics.pop()

        -- render product using outline shader
        self._outline_shader:bind()
        self._outline_shader:send("_texture_resolution", {self._outline_render_texture:get_size()})
        self:render(self._outline_render_texture._native, x - self._outline_render_offset_x, y - self._outline_render_offset_y)
        self._outline_shader:unbind()
    end

    draw_glyph(x, y)
end

--- @overload
function rt.Glyph:update(delta)
    self._elapsed_time = self._elapsed_time + delta
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

--- @brief
function rt.Glyph:set_n_visible_characters(n)
    self._n_visible_characters = clamp(n, 0, self:get_n_characters())
end

--- @brief
function rt.Glyph:get_n_visible_characters()
    return self._n_visible_characters
end

--- @brief [internal]
function rt.Glyph:_get_font()
    return self._font[self._style]
end

--- @brief [internal] test glyph
function rt.test.glyph()
    error("TODO")
end