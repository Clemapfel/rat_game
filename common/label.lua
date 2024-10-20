--[[
render all non-animated glyphs to a texture
render all animated glyphs on top
    group by animation and shader
]]

rt.settings.label = {
    outline_offset_padding = 5
}

--- @class rt.TextEffect
rt.TextEffect = meta.new_enum("TextEffect", {
    NONE = "NONE",
    SHAKE = "SHAKE",
    WAVE = "WAVE",
    RAINBOW = "RAINBOW"
})

---@class rt.JustifyMode
rt.JustifyMode = meta.new_enum("JustifyMode", {
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    CENTER = "CENTER"
})

--- @class rt.Label
rt.Label = meta.new_type("Label", rt.Widget, rt.Updatable, function(text, font, monospace_font)
    if font == nil then font = rt.settings.font.default end
    if monospace_font == nil then monospace_font = rt.settings.font.default_mono end

    local out = meta.new(rt.Label, {
        _raw = text,
        _font = font,
        _monospace_font = monospace_font,
        _justify_mode = rt.JustifyMode.LEFT,
        
        _n_visible_characters = -1,
        _elapsed = 0,

        _glyphs = {},
        _n_glyphs = 0,
        _n_characters = 0,
        _n_lines = 0,
        _glyphs_only = meta.make_weak({}),
        _non_outlined_glyphs = meta.make_weak({}),
        _outlined_glyphs = meta.make_weak({}),
        _animation_render = meta.make_weak({}),

        _use_outline = false,
        _use_animation = false,

        _outline_texture_offset_x = 0,
        _outline_texture_offset_y = 0,
        _outline_texture_justify_left_offset = 0,
        _outline_texture_justify_center_offset = 0,
        _outline_texture_justify_right_offset = 0,
        _outline_texture = rt.RenderTexture(1, 1),
        _swap_texture = rt.RenderTexture(1, 1),
        _outline_texture_w = 1,
        _outline_texture_h = 1,

        _width = 0,
        _height = 0
    })
    return out
end, {
    outline_shader = rt.Shader("common/glyph_outline.glsl"),
    render_shader = rt.Shader("common/glyph_render.glsl"),
})

_bold_font = love.graphics.newFont("assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf", 20)
_regular_font = love.graphics.newFont("assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf", 20)

--- @brief
function rt.Label:_glyph_new(
    text, font, style,
    color_r, color_g, color_b,
    is_underlined,
    is_strikethrough,
    is_outlined,
    outline_r, outline_g, outline_b,
    is_effect_shake,
    is_effect_wave,
    is_effect_rainbow
)
    local font_native = font:get_native(style)
    local out = {
        text = text, -- necessary for beat weights
        glyph = love.graphics.newTextBatch(font_native, text),
        font = font_native,
        is_underlined = is_underlined,
        is_strikethrough = is_strikethrough,
        is_outlined = is_outlined,
        outline_color = {outline_r, outline_g, outline_b, 1},
        is_effect_shake = is_effect_shake,
        is_effect_rainbow = is_effect_rainbow,
        is_effect_wave = is_effect_wave,
        color_r = color_r,
        color_g = color_g,
        color_b = color_b,
        n_visible_characters = utf8.len(text),
        n_characters = utf8.len(text),
        justify_left_offset = 0,
        justify_center_offset = 0,
        justify_right_offset = 0,
        row_index = 1,
        y = 0,
        x = 0,
        width = 0,
        height = 0,
        strikethrough_ax = nil,
        strikethrough_ay = nil,
        strikethrough_bx = nil,
        strikethrough_by = nil,
        underline_ax = nil,
        underline_ay = nil,
        underline_bx = nil,
        underline_by = nil
    }

    out.width = out.glyph:getWidth()
    out.height = out.glyph:getHeight()

    return out
end

--- @override
function rt.Label:draw()
    if self._n_glyphs == 0 then return end

    local render_order = self._glyphs_only
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.translate(self._bounds.x, self._bounds.y)

    local justify_offset = self._outline_texture_justify_left_offset
    if self._justify_mode == rt.JustifyMode.CENTER then
        justify_offset = self._outline_texture_justify_center_offset
    elseif self._justify_mode == rt.JustifyMode.RIGHT then
        justify_offset = self._outline_texture_justify_right_offset
    end

    love.graphics.setBlendMode("alpha", "premultiplied")
    -- canvas needs to be drawn premultiplied to avoid artifacting

    if self._use_outline and self._outline_texture ~= nil then
        self._outline_texture:draw(justify_offset + self._outline_texture_offset_x, self._outline_texture_offset_y)
    end

    if self._swap_texture ~= nil then
        self._swap_texture:draw(justify_offset + self._outline_texture_offset_x, self._outline_texture_offset_y)
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.translate(-self._bounds.x, -self._bounds.y)

    self:draw_bounds()
end

--- @override
function rt.Label:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self:_parse()
end

--- @override
function rt.Label:size_allocate(x, y, width, height)
    self:_apply_wrapping(width)
    self:_update_textures()
    self:_update_n_visible_characters()
end

--- @override
function rt.Label:measure()
    if self._is_realized == false then self:realize() end
    return self._width, self._height
end

--- @override
function rt.Label:update(delta)
    self._elapsed = self._elapsed + delta

    if self._use_animation then
        self:_update_textures()
    end
end

--- @brief
function rt.Label:set_justify_mode(mode)
    self._justify_mode = mode
end

--- @brief
function rt.Label:set_text(text)
    if self._raw == text then return end

    self._raw = text
    if self._is_realized then
        self:_parse()
        self._n_visible_characters = self._n_characters
        self:_update_textures()
    end
end

--- @brief
function rt.Label:get_text()
    return self._raw
end

--- @brief
function rt.Label:set_n_visible_characters(n)
    if self._n_visible_characters == n then return end
    self._n_visible_characters = n
    self:_update_n_visible_characters()
end

--- @brief
function rt.Label:get_n_visible_characters()
    return self._n_visible_characters
end

--- @brief
function rt.Label:get_n_characters()
    return self._n_characters
end

--- @brief
function rt.Label:get_n_lines()
    return self._n_lines
end

--- @brief
function rt.Label:set_opacity(alpha)
    self._opacity = alpha
end

--- @brief
function rt.Label:get_line_height()
    return self._font:get_bold_italic():getHeight()
end

do
    local _make_set = function(...)
        local n_args = _G._select("#", ...)
        local out = {}
        for i = 1, n_args do
            local arg = _G._select(i, ...)
            out[arg] = true
        end
        return out
    end

    local _syntax = {
        SPACE = " ",
        NEWLINE = "\n",
        TAB = "    ",
        ESCAPE_CHARACTER = "\\",
        BEAT = "|", -- pause when text scrolling
        BEAT_WEIGHTS = { -- factor, takes n times longer to scroll than a regular character
            ["|"] = 10,
            ["."] = 10,
            [","] = 4,
            ["!"] = 10,
            ["?"] = 10
        },

        -- regex patterns to match tags
        BOLD_TAG_START = _make_set("<b>", "<bold>"),
        BOLD_TAG_END = _make_set("</b>", "</bold>"),

        ITALIC_TAG_START = _make_set("<i>", "<italic>"),
        ITALIC_TAG_END = _make_set("</i>", "</italic>"),

        UNDERLINED_TAG_START = _make_set("<u>", "<underlined>"),
        UNDERLINED_TAG_END = _make_set("</u>", "</underlined>"),

        STRIKETHROUGH_TAG_START = _make_set("<s>", "<strikethrough>"),
        STRIKETHROUGH_TAG_END = _make_set("</s>", "</strikethrough>"),

        COLOR_TAG_START = _make_set("<col=(.*)>", "<color=(.*)>"),
        COLOR_TAG_END = _make_set("</col>", "</color>"),

        -- OUTLINE_COLOR_TAG_START = _make_set("<ocol=(.*)>", "<outline_color=(.*)>"),
        -- OUTLINE_COLOR_TAG_END = _make_set("</ocol>", "</outline_color>"),

        OUTLINE_TAG_START = _make_set("<o>", "<outline>"),
        OUTLINE_TAG_END = _make_set("</o>", "</outline>"),

        BACKGROUND_TAG_START = _make_set("<bg=(.*)>", "<background=(.*)>"),
        BACKGROUND_TAG_END = _make_set("</bg>", "</background>"),

        EFFECT_SHAKE_TAG_START = _make_set("<shake>", "<fx_shake>"),
        EFFECT_SHAKE_TAG_END = _make_set("</shake>", "</fx_shake>"),
        EFFECT_WAVE_TAG_START = _make_set("<wave>", "<fx_wave>"),
        EFFECT_WAVE_TAG_END = _make_set("</wave>", "</fx_wave>"),
        EFFECT_RAINBOW_TAG_START = _make_set("<rainbow>", "<fx_rainbow>"),
        EFFECT_RAINBOW_TAG_END = _make_set("</rainbow>", "</fx_rainbow>"),

        MONOSPACE_TAG_START = _make_set("<tt>", "<mono>"),
        MONOSPACE_TAG_END = _make_set("</tt>", "</mono>")
    }

    local _sequence_to_settings_key = {}
    for set_settings_key in range(
        {_syntax.BOLD_TAG_START, "is_bold"},
        {_syntax.BOLD_TAG_END, "is_bold"},

        {_syntax.ITALIC_TAG_START, "is_italic"},
        {_syntax.ITALIC_TAG_END, "is_italic"},

        {_syntax.UNDERLINED_TAG_START, "is_underlined"},
        {_syntax.UNDERLINED_TAG_END, "is_underlined"},

        {_syntax.STRIKETHROUGH_TAG_START, "is_strikethrough"},
        {_syntax.STRIKETHROUGH_TAG_END, "is_strikethrough"},

        --{_syntax.COLOR_TAG_START, "color_active"},
        {_syntax.COLOR_TAG_END, "color_active"},

        --{_syntax.OUTLINE_COLOR_TAG_START, "outline_color_active"},
        --{_syntax.OUTLINE_COLOR_TAG_END, "outline_color_active"},

        {_syntax.OUTLINE_TAG_START, "is_outlined"},
        {_syntax.OUTLINE_TAG_END, "is_outlined"},

        {_syntax.EFFECT_SHAKE_TAG_START, "is_effect_shake"},
        {_syntax.EFFECT_SHAKE_TAG_END, "is_effect_shake"},
        {_syntax.EFFECT_WAVE_TAG_START, "is_effect_wave"},
        {_syntax.EFFECT_WAVE_TAG_END, "is_effect_wave"},
        {_syntax.EFFECT_RAINBOW_TAG_START, "is_effect_rainbow"},
        {_syntax.EFFECT_RAINBOW_TAG_END, "is_effect_rainbow"},

        {_syntax.MONOSPACE_TAG_START, "is_mono"},
        {_syntax.MONOSPACE_TAG_END, "is_mono"}
    ) do
        local set, settings_key = table.unpack(set_settings_key)
        for x in keys(set) do
            _sequence_to_settings_key[x] = settings_key
        end
    end

    local _sub = utf8.sub
    local _insert = table.insert
    local _concat = table.concat
    local _find = string.find   -- safe as non-utf8 because it is only used on control sequences
    local _max = math.max
    local _min = math.min
    local _floor = math.floor
    local _rt_palette = rt.Palette
    local _rt_color_unpack = rt.color_unpack
    
    --- @brief [internal]
    function rt.Label:_parse()
        self._glyphs = {}
        self._glyphs_only = meta.make_weak({})
        self._non_outlined_glyphs = meta.make_weak({})
        self._outlined_glyphs = meta.make_weak({})

        self._n_glyphs = 0
        self._n_characters = 0
        self._use_outline = false
        self._use_animation = false

        local glyphs = self._glyphs
        local glyph_indices = self._glyph_indices

        local settings = {
            is_bold = false,
            is_italic = false,
            is_bold = false,
            is_italic = false,
            is_outlined = false,
            is_underlined = false,
            is_strikethrough = false,

            color = "TRUE_WHITE",
            color_active = false,
            outline_color = "TRUE_BLACK",
            outline_color_active = false,

            is_mono = false,

            is_effect_rainbow = false,
            is_effect_shake = false,
            is_effect_wave = false
        }

        local at = function(i)
            return _sub(self._raw, i, i)
        end

        local i = 1
        local s = at(i)
        local current_word = {}

        local push_glyph = function()
            if #current_word == 0 then return end

            local style = rt.FontStyle.REGULAR
            if settings.is_bold and settings.is_italic then
                style = rt.FontStyle.BOLD_ITALIC
            elseif settings.is_bold then
                style = rt.FontStyle.BOLD
            elseif settings.is_italic then
                style = rt.FontStyle.ITALIC
            end

            local font = self._font
            if settings.is_mono == true then
                font = self._monospace_font
            end
            
            local color_r, color_g, color_b = 1, 1, 1
            if not settings.is_effect_rainbow and settings.color_active then
                color_r, color_g, color_b = _rt_color_unpack(_rt_palette[settings.color])
            end
            
            local outline_color_r, outline_color_g, outline_color_b = 0, 0, 0
            if settings.outline_color_active then
                outline_color_r, outline_color_g, outline_color_b = _rt_color_unpack(_rt_palette[settings.outline_color])
            end

            local to_insert = self:_glyph_new(
                _concat(current_word), font, style,
                color_r, color_g, color_b,
                settings.is_underlined,
                settings.is_strikethrough,
                settings.is_outlined,
                outline_color_r, outline_color_g, outline_color_b,
                settings.is_effect_shake,
                settings.is_effect_wave,
                settings.is_effect_rainbow
            )

            _insert(glyphs, to_insert)

            if settings.is_outlined then
               _insert(self._outlined_glyphs, to_insert)
                self._use_outline = true
            else
                _insert(self._non_outlined_glyphs, to_insert)
            end

            if settings.is_effect_shake or settings.is_effect_wave or settings.is_effect_rainbow then
                self._use_animation = true
            end

            _insert(self._glyphs_only, to_insert)

            self._n_characters = self._n_characters + to_insert.n_visible_characters
            self._n_glyphs = self._n_glyphs + 1
            current_word = {}
        end

        local function throw_parse_error(reason)
            rt.error("In rt.Label._parse: Error at position `" .. tostring(i) .. "`: " .. reason)
        end
        
        local function step(n)  
            i = i + n
            s = at(i)
        end
        
        local n_characters = utf8.len(self._raw)
        while i <= n_characters do
            if s == _syntax.ESCAPE_CHARACTER then
                step(1)
                _insert(current_word, s)
                step(1)
                goto continue;
            elseif s == " " then
                push_glyph()
                _insert(glyphs, _syntax.SPACE)
            elseif s == "\n" then
                push_glyph()
                _insert(glyphs, _syntax.NEWLINE)
            elseif s == "\t" then
                push_glyph()
                _insert(glyphs, _syntax.TAB)
            elseif s == _syntax.BEAT then
                push_glyph() -- remove?
                _insert(glyphs, _syntax.BEAT)
            elseif s == "<" then
                push_glyph()

                -- get tag
                local sequence = {}
                local sequence_i = 0
                local sequence_s
                local is_closing_tag = false
                repeat
                    if i + sequence_i > n_characters then
                        throw_parse_error("malformed tag, `" .. _concat(sequence) .. "` reached end of text")
                    end

                    sequence_s = at(i + sequence_i)
                    if sequence_s == "/" then
                        is_closing_tag = true
                    end

                    _insert(sequence, sequence_s)
                    sequence_i = sequence_i + 1
                until sequence_s == ">"

                sequence = _concat(sequence)

                local settings_key = _sequence_to_settings_key[sequence]
                if settings_key ~= nil then
                    if is_closing_tag then
                        if settings[settings_key] == false then
                            throw_parse_error("trying to close region with `" .. sequence .. "`, but not such region is open")
                        end

                        settings[settings_key] = false
                    else
                        if settings[settings_key] == true then
                            throw_parse_error("trying to open region with `" .. sequence .. "`, but such a region is already open")
                        end

                        settings[settings_key] = true
                    end
                else
                    -- parse out color string
                    local found, new_color
                    for color_tag in keys(_syntax.COLOR_TAG_START) do
                        found, _, new_color = _find(sequence, color_tag)
                        if found ~= nil then
                            if rt.Palette[new_color] == nil then
                                throw_parse_error("malformed color tag: color `" .. new_color .. "` unknown")
                            end

                            settings.color = new_color
                            settings.color_active = true
                            break
                        end
                    end

                    if found == nil then
                        for color_tag in keys(_syntax.OUTLINE_COLOR_TAG_START) do
                            found, _, new_color = _find(sequence, color_tag)
                            if found ~= nil then
                                if rt.Palette[new_color] == nil then
                                    throw_parse_error("malformed color tag: color `" .. new_color .. "` unknown")
                                end

                                settings.outline_color = new_color
                                settings.outline_color_active = true
                                break
                            end
                        end
                    end

                    if found == nil then
                        throw_parse_error("unrecognized tag `" .. sequence .. "`")
                    end
                end

                step(sequence_i - 1)
            else
               _insert(current_word, s)
            end
            step(1)
            ::continue::
        end
        push_glyph()

        if settings.is_bold then throw_parse_error("reached end of text, but bold region is still open") end
        if settings.is_italic then throw_parse_error("reached end of text, but italic region is still open") end
        if settings.color_active then throw_parse_error("reached end of text, but colored region is still open") end
        if settings.outline_color_active then throw_parse_error("reached end of text, but outline color region is still open") end
        if settings.is_effect_shake then throw_parse_error("reached end of text, but effect shake region is still open") end
        if settings.is_effect_wave then throw_parse_error("reached end of text, but effect wave region is still open") end
        if settings.is_effect_rainbow then throw_parse_error("reached end of text, but effect rainbow region is still open") end
        if settings.is_underlined then throw_parse_error("reached end of text, but effect underlined region is still open") end
        if settings.is_strikethrough then throw_parse_error("reached end of text, but effect strikethrough region is still open") end
        if settings.is_outlined then throw_parse_error("reached end of text, but effect outline region is still open") end

        -- estimate size before wrapping
        local max_width = 0
        local width = 0
        local n_rows = 1

        local space_w = self._font:measure_glyph(_syntax.SPACE)
        local tab_w = self._font:measure_glyph(_syntax.TAB)

        for glyph in values(self._glyphs) do
            if glyph == _syntax.SPACE then
                width = width + space_w
            elseif glyph == _syntax.TAB then
                width = width + tab_w
            elseif glyph == _syntax.NEWLINE then
                max_width = _max(max_width, width)
                width = 0
                n_rows = n_rows + 1
            elseif glyph == _syntax.BEAT then
                -- noop
            else
                width = width + glyph.width
            end
        end

        self._width = _max(max_width, width)
        self._height = n_rows * self._font:get_native(rt.FontStyle.BOLD_ITALIC):getHeight()

        if self._n_visible_characters == -1 then
            self._n_visible_characters = n_characters
        end
    end

    local _padding = rt.settings.label.outline_offset_padding

    --- @brief [internal]
    function rt.Label:_apply_wrapping()
        local current_line_width = 0
        local max_line_w = 0

        local bold_italic = self._font:get_native(rt.FontStyle.BOLD_ITALIC)
        local space_w = bold_italic:getWidth(_syntax.SPACE)
        local tab_w = bold_italic:getWidth(_syntax.TAB)
        local line_height = bold_italic:getHeight()

        local glyph_x, glyph_y = 0, 0
        local max_w = self._bounds.width
        local row_i = 1
        local is_first_word = true

        local row_widths = {}
        local row_w = 0
        local max_glyph_x = 0
        local newline = function()
            max_glyph_x = _max(max_glyph_x, glyph_x)
           _insert(row_widths, glyph_x)
            if is_first_word ~= true then
                glyph_x = 0
                glyph_y = glyph_y + line_height
                row_i = row_i + 1
            end
        end

        local min_x, max_x, min_y, max_y = POSITIVE_INFINITY, NEGATIVE_INFINITY, POSITIVE_INFINITY, NEGATIVE_INFINITY
        local min_outline_y, max_outline_y = POSITIVE_INFINITY, NEGATIVE_INFINITY
        local max_outline_row_w = NEGATIVE_INFINITY

        for glyph in values(self._glyphs) do
            if glyph == _syntax.SPACE then
                if glyph_x ~= 0 then -- skip pre-trailing whitespaces
                    glyph_x = glyph_x + space_w
                    row_w = row_w + space_w
                end
                if glyph_x > max_w then newline() end
            elseif glyph == _syntax.TAB then
                glyph_x = glyph_x + tab_w
                row_w = row_w + tab_w
                if glyph_x > max_w then newline() end
            elseif glyph == _syntax.NEWLINE then
                newline()
            elseif glyph == _syntax.BEAT then
                -- noop
            else
                if glyph_x + glyph.width >= max_w then
                    newline()
                end

                glyph.x = glyph_x
                glyph.y = glyph_y
                glyph.row_index = row_i

                if glyph.is_outlined then
                    min_outline_y = _min(min_outline_y, glyph.y)
                    max_outline_y = _max(max_outline_y, glyph.y + glyph.height)
                end

                if glyph.is_underlined or glyph.is_strikethrough then
                    local font = glyph.font
                    local underline_y = font:getBaseline() - font:getDescent() + 2
                    local strikethrough_y = font:getBaseline() - 2

                    if glyph.is_underlined then
                        glyph.underline_ax = glyph.x
                        glyph.underline_ay = _floor(glyph.y + underline_y)
                        glyph.underline_bx = glyph.x + glyph.width
                        glyph.underline_by = glyph.underline_ay
                    end

                    if glyph.is_strikethrough then
                        glyph.strikethrough_ax = glyph.x
                        glyph.strikethrough_ay = _floor(glyph.y + strikethrough_y)
                        glyph.strikethrough_bx = glyph.x + glyph.width
                        glyph.strikethrough_by = glyph.strikethrough_ay
                    end
                end

                min_x = _min(min_x, glyph.x)
                min_y = _min(min_y, glyph.y)
                max_x = _max(max_x, glyph.x + glyph.width)
                max_y = _max(max_y, glyph.y + glyph.height)

                glyph_x = glyph_x + glyph.width
            end

            is_first_word = false
        end
        _insert(row_widths, glyph_x)

        if max_w == POSITIVE_INFINITY then
            max_w = _min(max_w, self._width)
        end

        -- update justify offsets
        for glyph in values(self._glyphs_only) do
            glyph.justify_center_offset = (max_w - row_widths[glyph.row_index]) / 2
            glyph.justify_right_offset = (max_w - row_widths[glyph.row_index])
        end

        self._width = max_x - min_x
        self._height = line_height * row_i --max_y - min_y
        self._n_lines = row_i

        self._outline_texture_offset_x = -_padding
        self._outline_texture_offset_y = -_padding
        local outline_texture_w = self._width + 2 * _padding
        local outline_texture_h = self._height + 2 * _padding

        if outline_texture_w < 1 then outline_texture_w = 1 end
        if outline_texture_h < 1 then outline_texture_h = 1 end

        self._outline_texture_justify_left_offset = 0
        self._outline_texture_justify_center_offset = _floor((max_w - outline_texture_w) * 0.5) + _padding
        self._outline_texture_justify_right_offset = (max_w - outline_texture_w) + _padding
        self._outline_texture_width = outline_texture_w
        self._outline_texture_height = outline_texture_h

        if self._use_outline and self._width > 0 and self._height > 0 then
            if self._outline_texture ~= nil then
                self._outline_texture:free()
            end
            self._outline_texture = rt.RenderTexture(outline_texture_w, outline_texture_h, 0, "rgba4")
            self.outline_shader:send("texture_resolution", {outline_texture_w, outline_texture_h})
            self.outline_shader:send("outline_color", { rt.color_unpack(rt.Palette.BLACK) })
        end

        if self._swap_texture ~= nil then
            self._swap_texture:free()
        end

        self._swap_texture = rt.RenderTexture(outline_texture_w, outline_texture_h, 0, "rgba4")
        self:_update_n_visible_characters()
    end

    --- @brief [internal]
    function rt.Label:_update_n_visible_characters()
        local n_characters_drawn = 0
        for glyph in values(self._glyphs_only) do
            if n_characters_drawn > self._n_visible_characters then
                glyph.n_visible_characters = 0
            else
                glyph.n_visible_characters = self._n_visible_characters - n_characters_drawn
            end
            n_characters_drawn = n_characters_drawn + glyph.n_characters
        end
    end

    --- @brief [internal]
    function rt.Label:_update_textures()
        if self._n_glyphs == 0 then return end

        love.graphics.push()
        love.graphics.reset()

        love.graphics.setLineWidth(2)

        if self._use_outline then
            self._swap_texture:bind_as_render_target()
            love.graphics.clear(true, false, false)
            self.render_shader:bind()
            for glyph in values(self._outlined_glyphs) do
                self.render_shader:send("n_visible_characters", glyph.n_visible_characters)
                self.render_shader:send("is_effect_rainbow", glyph.is_effect_rainbow)
                self.render_shader:send("is_effect_wave", glyph.is_effect_wave)
                self.render_shader:send("is_effect_shake", glyph.is_effect_shake)
                self.render_shader:send("elapsed", self._elapsed)
                love.graphics.setColor(glyph.color_r, glyph.color_g, glyph.color_b, 1)
                love.graphics.draw(glyph.glyph, glyph.x + _padding, glyph.y + _padding)

                if glyph.is_underlined then
                    love.graphics.line(glyph.underline_ax, glyph.underline_ay, glyph.underline_bx, glyph.underline_by)
                end

                if glyph.is_strikethrough then
                    love.graphics.line(glyph.strikethrough_ax, glyph.strikethrough_ay, glyph.strikethrough_bx, glyph.strikethrough_by)
                end
            end
            self.render_shader:unbind()

            self._swap_texture:unbind_as_render_target()

            self._outline_texture:bind_as_render_target()
            love.graphics.clear(true, false, false)
            self.outline_shader:bind()
            self.outline_shader:send("texture_resolution", {self._outline_texture_width, self._outline_texture_height})
            self._swap_texture:draw(0, 0)
            self.outline_shader:unbind()
            self._outline_texture:unbind_as_render_target()
        end

        self._swap_texture:bind_as_render_target()
        love.graphics.clear(true, false, false)
        self.render_shader:bind()
        for glyph in values(self._non_outlined_glyphs) do
            self.render_shader:send("n_visible_characters", glyph.n_visible_characters)
            self.render_shader:send("is_effect_rainbow", glyph.is_effect_rainbow)
            self.render_shader:send("is_effect_wave", glyph.is_effect_wave)
            self.render_shader:send("is_effect_shake", glyph.is_effect_shake)
            self.render_shader:send("elapsed", self._elapsed)
            love.graphics.setColor(glyph.color_r, glyph.color_g, glyph.color_b, 1)
            love.graphics.draw(glyph.glyph, glyph.x, glyph.y + _padding)

            if glyph.is_underlined then
                love.graphics.line(glyph.underline_ax, glyph.underline_ay, glyph.underline_bx, glyph.underline_by)
            end

            if glyph.is_strikethrough then
                love.graphics.line(glyph.strikethrough_ax, glyph.strikethrough_ay, glyph.strikethrough_bx, glyph.strikethrough_by)
            end
        end
        self.render_shader:unbind()
        self._swap_texture:unbind_as_render_target()

        love.graphics.pop()
    end

    --- @brief
    function rt.Label:update_n_visible_characters_from_elapsed(elapsed, letters_per_second)
        local so_far = elapsed
        local step = 1 / letters_per_second
        local n_visible = 0
        local weights = _syntax.BEAT_WEIGHTS
        local max_row = 0
        for glyph in values(self._glyphs) do
            if meta.is_table(glyph) then
                if so_far <= 0 then
                    glyph.n_visible_characters = 0
                else
                    local text = glyph.text
                    local n_seen = 1
                    for i = 1, glyph.n_characters do
                        local weight = weights[string.sub(glyph.text, i, i)]
                        if weight == nil then
                            so_far = so_far - step
                        else
                            so_far = so_far - weight * step
                        end

                        n_visible = n_visible + 1
                        n_seen = n_seen + 1
                        if so_far < 0 then break end
                    end
                    glyph.n_visible_characters = n_seen
                    max_row = math.max(max_row, glyph.row_index)
                end
            else
                local weight = weights[glyph]
                if weight ~= nil then
                    so_far = so_far - weight * step
                end
            end
        end

        self:_update_textures()
        local is_done = n_visible >= self._n_characters
        local rest_delta = so_far
        return is_done, max_row, so_far
    end
end  -- do-end


