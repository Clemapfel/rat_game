--[[
render all non-animated glyphs to a texture
render all animated glyphs on top
    group by animation and shader
]]

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
rt.Label = meta.new_type("Label", rt.Widget, rt.Animation, function(text, font, monospace_font)
    if font == nil then font = rt.settings.font.default end
    if monospace_font == nil then monospace_font = rt.settings.font.default_mono end

    return meta.new(rt.Label, {
        _raw = text,
        _font = font,
        _monospace_font = monospace_font,
        _justify_mode = rt.JustifyMode.LEFT,

        _outline_shader = rt.Shader("common/glyph_outline.glsl"),
        _render_shader = rt.Shader("common/glyph_render.glsl"),

        _glyphs = {},
        _glyph_indices = {}
    })
end)

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
    local out = {
        glyph = love.graphics.newTextBatch(font[style], text, {{color_r, color_g, color_b, 1}, text}),
        is_underlined = is_underlined,
        is_strikethrough = is_strikethrough,
        is_outlined = is_outlined,
        outline_color = {outline_r, outline_g, outline_b, 1},
        shake = is_effect_shake,
        rainbow = is_effect_rainbow,
        wave = is_effect_wave,
        n_visible_characters = utf8.len(text),
        y = 0,
        x = 0
    }

    return out
end

--- @brief
function rt.Label:_glyph_draw(glyph)
    love.graphics.draw(glyph.glyph, glyph.x, glyph.y)
end

--- @override
function rt.Label:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self:_parse()
end

--- @override
function rt.Label:size_allocate(x, y, width, height)

end

--- @override
function rt.Label:measure()
    return 100, 100
end

--- @override
function rt.Label:update(delta)
end

--- @override
function rt.Label:draw()
    local glyph_indices = self._glyph_indices
    local glyph_draw = self._glyph_draw
    local glyphs = self._glyphs
    for i in values(glyph_indices) do
        glyph_draw(glyphs[i])
    end
end

--- @brief
function rt.Label:set_justify_mode(mode)
    self._justify_mode = mode
end

--- @brief
function rt.Label:set_text(text)
end

--- @brief
function rt.Label:set_n_visible_characters(n)
end

--- @brief
function rt.Label:get_n_visible_characters()
end

--- @brief
function rt.Label:update_n_visible_characters_from_elapsed(elapsed, letters_per_second)
end

--- @brief
function rt.Label:get_n_characters()
end

--- @brief
function rt.Label:get_n_lines()
end

--- @brief
function rt.Label:set_opacity(alpha)
end

--- @brief
function rt.Label:get_line_height()
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

        OUTLINE_COLOR_TAG_START = _make_set("<ocol=(.*)>", "<outline_color=(.*)>"),
        OUTLINE_COLOR_TAG_END = _make_set("</ocol>", "</outline_color>"),

        OUTLINE_TAG_START = _make_set("<o>", "<outline>"),
        OUTLINE_TAG_END = _make_set("</o>", "</outline>"),

        BACKGROUND_TAG_START = _make_set("<bg=(.*)>", "<background=(.*)>"),
        BACKGROUND_TAG_END = _make_set("</bg>", "</background>"),

        EFFECT_SHAKE_TAG_START = _make_set("<shake>", "<fx_shake>"),
        EFFECT_SHAKE_TAG_END = _make_set("</shake>", "</fx_shake>"),
        EFFECT_WAVE_TAG_START = _make_set("<wave>", "<fx_wave>"),
        EFFECT_WAVE_TAG_END = _make_set("</wave", "</fx_wave>"),
        EFFECT_RAINBOW_TAG_START = _make_set("<rainbow>", "<fx_rainbow>"),
        EFFECT_RAINBOW_TAG_END = _make_set("</rainbow>", "</fx_rainbow>"),

        MONOSPACE_TAG_START = _make_set("<tt>", "<mono>"),
        MONOSPACE_TAG_END = _make_set("</tt>", "</mono>")
    }
        
    local _string_sub = string.sub
    local _insert = table.insert
    local _concat = table.concat
    local _find = string.find
    local _rt_palette = rt.Palette
    local _rt_color_unpack = rt.color_unpack
    
    --- @brief [internal]
    function rt.Label:_parse()
        self._glyphs = {}
        self._glyph_indices = {}
        self._n_glyphs = 0
        self._n_characters = 0

        local glyphs = self._glyphs
        local glyph_indices = self._glyph_indices

        local is_bold = false
        local is_italic = false
        local is_colored = false
        local is_outlined = false
        local is_underlined = false
        local is_strikethrough = false

        local color = {"TRUE_WHITE"} -- string reference
        local outline_color = {"TRUE_BLACK"}
        local outline_color_active = false

        local is_mono = false

        local is_effect_rainbow = false
        local is_effect_shake = false
        local is_effect_wave = false

        local at = function(i)
            return _string_sub(self._raw, i, i)
        end

        local i = 1
        local s = at(i)
        local current_word = {}

        local push_glyph = function()
            if #current_word == 0 then return end

            local style = rt.FontStyle.REGULAR
            if is_bold and is_italic then
                style = rt.FontStyle.BOLD_ITALIC
            elseif is_bold then
                style = rt.FontStyle.BOLD
            elseif is_italic then
                style = rt.FontStyle.ITALIC
            end

            local font = self._font
            if is_mono == true then
                font = self._monospace_font
            end
            
            local color_r, color_g, color_b = 1, 1, 1
            if not is_effect_rainbow then
                color_r, color_g, color_b = _rt_color_unpack(_rt_palette[color])
            end
            
            local outline_color_r, outline_color_g, outline_color_b = 0, 0, 0
            if outline_color_active then
                outline_color_r, outline_color_g, outline_color_b = _rt_color_unpack(_rt_palette[outline_color])
            end
            
            local to_insert = self:_glyph_new(
                _concat(current_word), font, style,
                color_r, color_g, color_b,
                is_underlined,
                is_strikethrough,
                is_outlined,
                outline_color_r, outline_color_g, outline_color_b,
                is_effect_shake,
                is_effect_wave,
                is_effect_rainbow
            )
            
            _insert(glyphs, to_insert)
            _insert(glyph_indices, self._n_glyphs)

            self._n_characters = self._n_characters + to_insert.n_visible_characters
            self._n_glyphs = self._n_glyphs + 1
        end

        local function throw_parse_error(reason)
            rt.error("In rt.Label._parse: Error at position `" .. tostring(i) .. "`: " .. reason)
        end
        
        local function step(n)  
            i = i + n
            s = at(i)
        end
        
        local n_characters = utf8.len(self._raw)
        
        local function tag_matches(tags)
            local sequence = {}
            local sequence_i = 0
            local sequence_s
            repeat
                if i + sequence_i > n_characters then
                    throw_parse_error("malformed tag, reached end of text")
                end
                
                sequence_s = at(i + sequence_i)
                _insert(sequence, sequence_s)
                sequence_i = sequence_i + 1
            until sequence_s == ">"

            sequence = _concat(sequence)
            if tags[sequence] == true then
                step(sequence_i)
                return true
            end
            
            return false
        end
        
        local function color_tag_matches(which, to_assign)  
            local sequence = {}
            local color_i = 0
            local color_s 
            repeat
                if i + color_i > n_characters then
                    throw_parse_error("malformed color tag, reached end of text")
                end
                
                local color_s = at(i + color_i)
                _insert(sequence, color_s)
                color_i = color_i + 1
            until color_s == ">"

            sequence = _concat(sequence)

            for tag in keys(which) do
                local _, _, new_color = _find(sequence, tag)
                if not (new_color == nil) then
                    if _rt_palette[new_color] == nil then
                        throw_parse_error("malformed color tag: color `" .. new_color .. "` unknown")
                    end
                    to_assign[1] = new_color
                    step(color_i)
                    return true
                end
            end
        end
        
        local glyphs = self._glyphs

        while i <= n_characters do
            if s == _syntax.ESCAPE_CHARACTER then
                step(1)
                _insert(current_word, s)
                step(1)
                goto continue;
            elseif s == " " then
                _insert(current_word, " ")
                push_glyph() -- remove?
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

                -- TODO: get full tag, then compare, instead of getting full tag for all of these cases
                if tag_matches(_syntax.BOLD_TAG_START) then
                    if is_bold == true then
                        throw_parse_error("trying to open a bold region, but one is already open")
                    end
                    is_bold = true
                elseif tag_matches(_syntax.BOLD_TAG_END) then
                    if is_bold == false then
                        throw_parse_error("trying to close a bold region, but one is not open")
                    end
                    is_bold = false
                    -- italic
                elseif tag_matches(_syntax.ITALIC_TAG_START) then
                    if is_italic == true then
                        throw_parse_error("trying to open an italic region, but one is already open")
                    end
                    is_italic = true
                elseif tag_matches(_syntax.ITALIC_TAG_END) then
                    if is_italic == false then
                        throw_parse_error("trying to close an italic region, but one is not open")
                    end
                    is_italic = false
                    -- underlined
                elseif tag_matches(_syntax.UNDERLINED_TAG_START) then
                    if is_underlined == true then
                        throw_parse_error("trying to open an underlined region, but one is already open")
                    end
                    is_underlined = true
                elseif tag_matches(_syntax.UNDERLINED_TAG_END) then
                    if is_underlined == false then
                        throw_parse_error("trying to close an underlined region, but one is not open")
                    end
                    is_underlined = false
                    -- strikethrough
                elseif tag_matches(_syntax.STRIKETHROUGH_TAG_START) then
                    if is_strikethrough == true then
                        throw_parse_error("trying to open an strikethrough region, but one is already open")
                    end
                    is_strikethrough = true
                elseif tag_matches(_syntax.STRIKETHROUGH_TAG_END) then
                    if is_strikethrough == false then
                        throw_parse_error("trying to close an strikethrough region, but one is not open")
                    end
                    is_strikethrough = false
                    -- mono
                elseif tag_matches(_syntax.MONOSPACE_TAG_START) then
                    if is_mono == true then
                        throw_parse_error("trying to open an monospace region, but one is already open")
                    end
                    is_mono = true
                elseif tag_matches(_syntax.MONOSPACE_TAG_END) then
                    if is_mono == false then
                        throw_parse_error("trying to close an monospace region, but one is not open")
                    end
                    is_mono = false
                    -- outlined
                elseif tag_matches(_syntax.OUTLINE_TAG_START) then
                    if is_outlined == true then
                        throw_parse_error("trying to open an outlined region, but one is already open")
                    end
                    is_outlined = true
                elseif tag_matches(_syntax.OUTLINE_TAG_END) then
                    if is_outlined == false then
                        throw_parse_error("trying to close an outlined region, but one is not open")
                    end
                    is_outlined = false
                    -- color
                elseif color_tag_matches(_syntax.COLOR_TAG_START, color) then
                    if is_colored == true then
                        throw_parse_error("trying to open a color region, but one is already open")
                    end
                    is_colored = true
                elseif tag_matches(_syntax.COLOR_TAG_END) then
                    if is_colored == false then
                        throw_parse_error("trying to close a color region, but one is not open")
                    end
                    is_colored = false
                    color[1] = "TRUE_WHITE"
                    -- outline color
                elseif color_tag_matches(_syntax.OUTLINE_COLOR_TAG_START, outline_color) then
                    if outline_color_active == true then
                        throw_parse_error("trying to open a outline color region, but one is already open")
                    end
                    outline_color_active = true
                elseif tag_matches(_syntax.OUTLINE_COLOR_TAG_END) then
                    if outline_color_active == false then
                        throw_parse_error("trying to close a outline color region, but one is not open")
                    end
                    outline_color_active = false
                    color[1] = "TRUE_BLACK"
                    -- effect: shake
                elseif tag_matches(_syntax.EFFECT_SHAKE_TAG_START) then
                    if is_effect_shake == true then
                        throw_parse_error("trying to open an effect shake region, but one is already open")
                    end
                    is_effect_shake = true
                elseif tag_matches(_syntax.EFFECT_SHAKE_TAG_END) then
                    if is_effect_shake == false then
                        throw_parse_error("trying to close an effect shake region, but one is not open")
                    end
                    is_effect_shake = false
                    -- effect: wave
                elseif tag_matches(_syntax.EFFECT_WAVE_TAG_START) then
                    if is_effect_wave == true then
                        throw_parse_error("trying to open an effect wave region, but one is already open")
                    end
                    is_effect_wave = true
                elseif tag_matches(_syntax.EFFECT_WAVE_TAG_END) then
                    if is_effect_wave == false then
                        throw_parse_error("trying to close an effect wave region, but one is not open")
                    end
                    is_effect_wave = false
                    -- effect: rainbow
                elseif tag_matches(_syntax.EFFECT_RAINBOW_TAG_START) then
                    if is_effect_rainbow == true then
                        throw_parse_error("trying to open an effect rainbow region, but one is already open")
                    end
                    is_effect_rainbow = true
                elseif tag_matches(_syntax.EFFECT_RAINBOW_TAG_END) then
                    if is_effect_rainbow == false then
                        throw_parse_error("trying to close an effect rainbow region, but one is not open")
                    end
                    is_effect_rainbow = false
                else -- unknown tag
                    local sequence = {}
                    local sequence_i = 0
                    repeat
                        if i + sequence_i > n_characters then
                            throw_parse_error("malformed tag, reached end of text")
                        end
                        local sequence_s = at(i + sequence_i)
                        _insert(sequence, sequence_s)
                        sequence_i = sequence_i + 1
                    until sequence_s == ">"
                    throw_parse_error("unknown control sequence: " .. _concat(sequence))
                end
                goto continue
            else
                table.insert(current_word, s)
            end
            step(1)
            ::continue::
        end
        push_glyph()

        if is_bold then throw_parse_error("reached end of text, but bold region is still open") end
        if is_italic then throw_parse_error("reached end of text, but italic region is still open") end
        if is_colored then throw_parse_error("reached end of text, but colored region is still open") end
        if outline_color_active then throw_parse_error("reached end of text, but outline color region is still open") end
        if is_effect_shake then throw_parse_error("reached end of text, but effect shake region is still open") end
        if is_effect_wave then throw_parse_error("reached end of text, but effect wave region is still open") end
        if is_effect_rainbow then throw_parse_error("reached end of text, but effect rainbow region is still open") end
        if is_underlined then throw_parse_error("reached end of text, but effect underlined region is still open") end
        if is_strikethrough then throw_parse_error("reached end of text, but effect strikethrough region is still open") end
        if is_outlined then throw_parse_error("reached end of text, but effect outline region is still open") end
    end
end  -- do-end

function rt.Label:_parse() end