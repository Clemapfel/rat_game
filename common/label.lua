rt.settings.label = {
    pause_on_punctuation = true,
    default_scroll_speed = 50, -- letters per second
}

---@class rt.JustifyMode
rt.JustifyMode = meta.new_enum({
    LEFT = "left",
    RIGHT = "right",
    CENTER = "center"
})

--- @class rt.Label
--- @param text String
--- @param font rt.Font (or nil)
rt.Label = meta.new_type("Label", rt.Widget, function(text, font, monospace_font)
    if meta.is_nil(text) then
        text = ""
    end

    if meta.is_nil(font) then
        font = rt.settings.font.default
    end

    if meta.is_nil(monospace_font) then
        monospace_font = rt.settings.font.default_mono
    end

    local out = meta.new(rt.Label, {
        _raw = text,
        _font = font,
        _monospace_font = monospace_font,
        _justify_mode = rt.JustifyMode.LEFT,
        _glyphs = {},
        _opacity = 1,
        _n_characters = 0,
        _default_width = 0,
        _default_height = 0,
        _current_width = 0,
        _current_height = 0,
        _n_visible_characters = -1,
        _n_rows = 0,
    })
    return out
end)

--- @overload rt.Widget.realize
function rt.Label:realize()
    if not self:get_is_realized() then
        self:_parse()
        self:_update_default_size()
        self:set_is_animated(self._is_animated)
        self._is_realized = true
    end
end

--- @overload rt.Drawable.draw
function rt.Label:draw()
    if not self:get_is_visible() then return end
    for _, glyph in pairs(self._glyphs) do
        if meta.isa(glyph, rt.Glyph) then
            glyph:draw(self._opacity)
        end
    end
end

--- @overload rt.Animation.update
function rt.Label:update(delta)
    for _, glyph in pairs(self._glyphs) do
        if meta.isa(glyph, rt.Glyph) then
            glyph:update(delta)
        end
    end
end

--- @overload rt.Widget.size_allocate
function rt.Label:size_allocate(x, y, width, height)

    -- apply wrapping
    local syntax = rt.Label._syntax
    local space = self._font:get_bold_italic():getWidth(syntax.SPACE)
    local tab = self._font:get_bold_italic():getWidth(syntax.TAB)
    local line_height = self._font:get_bold_italic():getHeight()

    local glyph_x = x
    local glyph_y = y

    local row_widths = {0}
    local rows = {{}}
    local row_i = 1
    local line_width = 0
    local one_word_mode = true -- avoids wrapping of one-word labels

    for _, glyph in pairs(self._glyphs) do
        if glyph == syntax.SPACE then
            -- do not advance position, actual space is appended to glyphs
            table.insert(rows[row_i], syntax.SPACE)
            one_word_mode = false
        elseif glyph == syntax.TAB then
            glyph_x = glyph_x + tab
            line_width = line_width + tab
            table.insert(rows[row_i], syntax.TAB)
            one_word_mode = false
        elseif glyph == syntax.NEWLINE then
            glyph_x = x
            glyph_y = glyph_y + line_height
            row_widths[row_i] = line_width
            line_width = 0
            row_i = row_i + 1
            rows[row_i] = {}
            one_word_mode = false
        elseif meta.isa(glyph, rt.Glyph) then
            local w, h = glyph:get_size()
            if glyph_x - x + w >= width and not one_word_mode then
                glyph_x = x
                glyph_y = glyph_y + line_height
                glyph:set_position(glyph_x, glyph_y)
                glyph_x = glyph_x + w

                row_widths[row_i] = line_width
                line_width = w
                row_i = row_i + 1
                rows[row_i] = {glyph}
            else
                glyph:set_position(glyph_x, glyph_y)
                glyph_x = glyph_x + w

                line_width = line_width + w
                table.insert(rows[row_i], glyph)
            end
        end
    end
    row_widths[row_i] = line_width

    local min_x = POSITIVE_INFINITY
    local min_y = POSITIVE_INFINITY
    local max_x = NEGATIVE_INFINITY
    local max_y = NEGATIVE_INFINITY

    for i, row in ipairs(rows) do
        for _, glyph in ipairs(rows[i]) do
            if meta.isa(glyph, rt.Glyph) then
                local position_x, position_y = glyph:get_position()
                if self._justify_mode == rt.JustifyMode.LEFT then
                    position_x = position_x + self:get_margin_left() + self:get_margin_right()
                elseif self._justify_mode == rt.JustifyMode.CENTER then
                    position_x = position_x + (width - row_widths[i] - self:get_margin_left() - self:get_margin_right()) * 0.5
                elseif self._justify_mode == rt.JustifyMode.RIGHT then
                    position_x = position_x + (width - row_widths[i] - self:get_margin_left() - self:get_margin_right())
                end

                local w, h = glyph:get_size()
                min_x = math.min(min_x, position_x)
                min_y = math.min(min_y, position_y)
                max_x = math.max(max_x, position_x + w)
                max_y = math.max(max_y, position_y + h)

                glyph:set_position(position_x, position_y)
            end
        end
    end

    local w, h = max_x - min_x, max_y - min_y
    local x_offset, y_offset = 0, 0

    if x_offset ~= 0 or y_offset ~= 0 then

        min_x = POSITIVE_INFINITY
        min_y = POSITIVE_INFINITY
        max_x = NEGATIVE_INFINITY
        max_y = NEGATIVE_INFINITY

        for _, glyph in pairs(self._glyphs) do
            if meta.isa(glyph, rt.Glyph) then
                local position_x, position_y = glyph:get_position()
                glyph:set_position(position_x + x_offset, position_y + y_offset)

                w, h = glyph:get_size()
                min_x = math.min(min_x, position_x)
                min_y = math.min(min_y, position_y)
                max_x = math.max(max_x, position_x + w)
                max_y = math.max(max_y, position_y + h)
            end
        end
    end

    self._current_width = max_x - min_x
    self._current_height = max_y - min_y
    self._n_rows = #rows
end

--- @overload rt.Widget.measure
function rt.Label:measure()
    return math.max(self._current_width, select(1, self:get_minimum_size())) + self:get_margin_left() + self:get_margin_right(),
    math.max(self._current_height, select(2, self:get_minimum_size())) + self:get_margin_top() + self:get_margin_bottom()
end

-- control characters
rt.Label._syntax = {
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
    BOLD_TAG_START = rt.Set("<b>", "<bold>"),
    BOLD_TAG_END = rt.Set("</b>", "</bold>"),

    ITALIC_TAG_START = rt.Set("<i>", "<italic>"),
    ITALIC_TAG_END = rt.Set("</i>", "</italic>"),

    UNDERLINED_TAG_START = rt.Set("<u>", "<underlined>"),
    UNDERLINED_TAG_END = rt.Set("</u>", "</underlined>"),

    STRIKETHROUGH_TAG_START = rt.Set("<s>", "<strikethrough>"),
    STRIKETHROUGH_TAG_END = rt.Set("</s>", "</strikethrough>"),

    COLOR_TAG_START = rt.Set("<col=(.*)>", "<color=(.*)>"),
    COLOR_TAG_END = rt.Set("</col>", "</color>"),

    OUTLINE_COLOR_TAG_START = rt.Set("<ocol=(.*)>", "<outline_color=(.*)>"),
    OUTLINE_COLOR_TAG_END = rt.Set("</ocol>", "</outline_color>"),

    OUTLINE_TAG_START = rt.Set("<o>", "<outline>"),
    OUTLINE_TAG_END = rt.Set("</o>", "</outline>"),

    BACKGROUND_TAG_START = rt.Set("<bg=(.*)>", "<background=(.*)>"),
    BACKGROUND_TAG_END = rt.Set("</bg>", "</background>"),

    EFFECT_SHAKE_TAG_START = rt.Set("<shake>", "<fx_shake>"),
    EFFECT_SHAKE_TAG_END = rt.Set("</shake>", "</fx_shake>"),
    EFFECT_WAVE_TAG_START = rt.Set("<wave>", "<fx_wave>"),
    EFFECT_WAVE_TAG_END = rt.Set("</wave", "</fx_wave>"),
    EFFECT_RAINBOW_TAG_START = rt.Set("<rainbow>", "<fx_rainbow>"),
    EFFECT_RAINBOW_TAG_END = rt.Set("</rainbow>", "</fx_rainbow>"),

    MONOSPACE_TAG_START = rt.Set("<tt>", "<mono>"),
    MONOSPACE_TAG_END = rt.Set("</tt>", "</mono>")
}


--- @brief [internal] transform _raw into set of glyphs
function rt.Label:_parse()
    local first_parse = sizeof(self._glyphs) == 0
    local animation_necessary = false

    self._glyphs = {}
    self._n_characters = 0

    local bold = false
    local italic = false
    local is_colored = false
    local is_outlined = false
    local is_background = false
    local color = {"TRUE_WHITE"} -- string reference
    local outline_color = {"TRUE_BLACK"}
    local outline_color_active = false
    local mono = false
    local underlined = false
    local strikethrough = false
    local outlined = false
    local effect_rainbow = false
    local effect_shake = false
    local effect_wave = false

    local current_word = ""

    local i = 1
    local s = string.sub(self._raw, i, i)

    -- push `current_word` and apply formatting
    local function push_glyph()
        if current_word == "" then return end

        local style = rt.FontStyle.REGULAR
        if bold and italic then
            style = rt.FontStyle.BOLD_ITALIC
        elseif bold then
            style = rt.FontStyle.BOLD
        elseif italic then
            style = rt.FontStyle.ITALIC
        end

        local font = self._font
        if mono == true then
            font = self._monospace_font
        end

        local effects = {}
        if effect_rainbow then table.insert(effects, rt.TextEffect.RAINBOW) end
        if effect_shake then table.insert(effects, rt.TextEffect.SHAKE) end
        if effect_wave then table.insert(effects, rt.TextEffect.WAVE) end

        table.insert(self._glyphs, rt.Glyph(
            font,
            current_word,
            {
                font_style = style,
                color = rt.Palette[ternary(effect_rainbow, "TRUE_WHITE", color[1])],
                is_underlined = underlined,
                is_strikethrough = strikethrough,
                is_outlined = outlined,
                outline_color = ternary(outline_color_active, rt.Palette[outline_color[1]], nil),
                effects = effects
            }
        ))

        self._n_characters = self._n_characters + string.len(current_word)
        current_word = ""

        if effect_rainbow or effect_shake or effect_wave then
            animation_necessary = true
        end
    end

    -- throw error, with guides
    local function throw_parse_error(reason)
        rt.error("[rt] In rt.Label._parse: Error at position `" .. tostring(i) .. "`: " .. reason)
    end

    -- advance n characters
    local function step(n)
        if meta.is_nil(n) then n = 1 end
        i = i + n
        s = string.sub(self._raw, i, i)
    end

    -- check if next `#tag` characters match `tag`
    local function tag_matches(tags)
        local sequence = ""
        local sequence_i = 0
        repeat
            if i + sequence_i > string.len(self._raw) then
                throw_parse_error("malformed tag, reached end of text")
            end
            local sequence_s = string.sub(self._raw, i + sequence_i, i + sequence_i)
            sequence = sequence .. sequence_s
            sequence_i = sequence_i + 1
        until sequence_s == ">"

        for tag in pairs(tags) do
            if not meta.is_nil(string.find(sequence, tag)) then
                step(string.len(sequence))
                return true
            end
        end
        return false
    end

    -- test if upcoming control sequence matches COLOR_TAG_START
    local function color_tag_matches(which, to_assign)
        local sequence = ""
        local color_i = 0
        repeat
            if i + color_i > string.len(self._raw) then
                throw_parse_error("malformed color tag, reached end of text")
            end
            local color_s = string.sub(self._raw, i + color_i, i + color_i)
            sequence = sequence .. color_s
            color_i = color_i + 1
        until color_s == ">"

        for tag in pairs(which) do
            local _, _, new_color = string.find(sequence, tag)
            if not meta.is_nil(new_color) then
                if not meta.is_rgba(rt.Palette[new_color]) then
                    throw_parse_error("malformed color tag: color `" .. new_color .. "` unknown")
                end
                to_assign[1] = new_color
                step(string.len(sequence))
                return true
            end
        end
        return false
    end

    local syntax = rt.Label._syntax

    while i <= string.len(self._raw) do
        if s == syntax.ESCAPE_CHARACTER then
            step(1)
            current_word = current_word .. s
            step(1)
            goto continue;
        elseif s == " " then
            current_word = current_word .. " "
            push_glyph()
            table.insert(self._glyphs, syntax.SPACE)
        elseif s == "\n" then
            push_glyph()
            table.insert(self._glyphs, syntax.NEWLINE)
        elseif s == "\t" then
            push_glyph()
            table.insert(self._glyphs, syntax.TAB)
        elseif s == syntax.BEAT then
            push_glyph()
            table.insert(self._glyphs, syntax.BEAT)
        elseif s == "<" then
            push_glyph()
            -- bold
            if tag_matches(syntax.BOLD_TAG_START) then
                if bold == true then
                    throw_parse_error("trying to open a bold region, but one is already open")
                end
                bold = true
            elseif tag_matches(syntax.BOLD_TAG_END) then
                if bold == false then
                    throw_parse_error("trying to close a bold region, but one is not open")
                end
                bold = false
                -- italic
            elseif tag_matches(syntax.ITALIC_TAG_START) then
                if italic == true then
                    throw_parse_error("trying to open an italic region, but one is already open")
                end
                italic = true
            elseif tag_matches(syntax.ITALIC_TAG_END) then
                if italic == false then
                    throw_parse_error("trying to close an italic region, but one is not open")
                end
                italic = false
                -- underlined
            elseif tag_matches(syntax.UNDERLINED_TAG_START) then
                if underlined == true then
                    throw_parse_error("trying to open an underlined region, but one is already open")
                end
                underlined = true
            elseif tag_matches(syntax.UNDERLINED_TAG_END) then
                if underlined == false then
                    throw_parse_error("trying to close an underlined region, but one is not open")
                end
                underlined = false
                -- strikethrough
            elseif tag_matches(syntax.STRIKETHROUGH_TAG_START) then
                if strikethrough == true then
                    throw_parse_error("trying to open an strikethrough region, but one is already open")
                end
                strikethrough = true
            elseif tag_matches(syntax.STRIKETHROUGH_TAG_END) then
                if strikethrough == false then
                    throw_parse_error("trying to close an strikethrough region, but one is not open")
                end
                strikethrough = false
                -- mono
            elseif tag_matches(syntax.MONOSPACE_TAG_START) then
                if mono == true then
                    throw_parse_error("trying to open an monospace region, but one is already open")
                end
                mono = true
            elseif tag_matches(syntax.MONOSPACE_TAG_END) then
                if mono == false then
                    throw_parse_error("trying to close an monospace region, but one is not open")
                end
                mono = false
                -- outlined
            elseif tag_matches(syntax.OUTLINE_TAG_START) then
                if outlined == true then
                    throw_parse_error("trying to open an outlined region, but one is already open")
                end
                outlined = true
            elseif tag_matches(syntax.OUTLINE_TAG_END) then
                if outlined == false then
                    throw_parse_error("trying to close an outlined region, but one is not open")
                end
                outlined = false
                -- color
            elseif color_tag_matches(syntax.COLOR_TAG_START, color) then
                if is_colored == true then
                    throw_parse_error("trying to open a color region, but one is already open")
                end
                is_colored = true
            elseif tag_matches(syntax.COLOR_TAG_END) then
                if is_colored == false then
                    throw_parse_error("trying to close a color region, but one is not open")
                end
                is_colored = false
                color[1] = "TRUE_WHITE"
                -- outline color
            elseif color_tag_matches(syntax.OUTLINE_COLOR_TAG_START, outline_color) then
                if outline_color_active == true then
                    throw_parse_error("trying to open a outline color region, but one is already open")
                end
                outline_color_active = true
            elseif tag_matches(syntax.OUTLINE_COLOR_TAG_END) then
                if outline_color_active == false then
                    throw_parse_error("trying to close a outline color region, but one is not open")
                end
                outline_color_active = false
                color[1] = "TRUE_BLACK"
                -- effect: shake
            elseif tag_matches(syntax.EFFECT_SHAKE_TAG_START) then
                if effect_shake == true then
                    throw_parse_error("trying to open an effect shake region, but one is already open")
                end
                effect_shake = true
            elseif tag_matches(syntax.EFFECT_SHAKE_TAG_END) then
                if effect_shake == false then
                    throw_parse_error("trying to close an effect shake region, but one is not open")
                end
                effect_shake = false
                -- effect: wave
            elseif tag_matches(syntax.EFFECT_WAVE_TAG_START) then
                if effect_wave == true then
                    throw_parse_error("trying to open an effect wave region, but one is already open")
                end
                effect_wave = true
            elseif tag_matches(syntax.EFFECT_WAVE_TAG_END) then
                if effect_wave == false then
                    throw_parse_error("trying to close an effect wave region, but one is not open")
                end
                effect_wave = false
                -- effect: rainbow
            elseif tag_matches(syntax.EFFECT_RAINBOW_TAG_START) then
                if effect_rainbow == true then
                    throw_parse_error("trying to open an effect rainbow region, but one is already open")
                end
                effect_rainbow = true
            elseif tag_matches(syntax.EFFECT_RAINBOW_TAG_END) then
                if effect_rainbow == false then
                    throw_parse_error("trying to close an effect rainbow region, but one is not open")
                end
                effect_rainbow = false
            else -- unknown tag
                local sequence = ""
                local sequence_i = 0
                repeat
                    if i + sequence_i > string.len(self._raw) then
                        throw_parse_error("malformed tag, reached end of text")
                    end
                    local sequence_s = string.sub(self._raw, i + sequence_i, i + sequence_i)
                    sequence = sequence .. sequence_s
                    sequence_i = sequence_i + 1
                until sequence_s == ">"
                throw_parse_error("unknown control sequence: " .. sequence)
            end
            goto continue
        else
            current_word = current_word .. s
        end
        step()
        ::continue::
    end
    push_glyph()

    if bold then throw_parse_error("reached end of text, but bold region is still open") end
    if italic then throw_parse_error("reached end of text, but italic region is still open") end
    if is_colored then throw_parse_error("reached end of text, but colored region is still open") end
    if outline_color_active then throw_parse_error("reached end of text, but outline color region is still open") end
    if effect_shake then throw_parse_error("reached end of text, but effect shake region is still open") end
    if effect_wave then throw_parse_error("reached end of text, but effect wave region is still open") end
    if effect_rainbow then throw_parse_error("reached end of text, but effect rainbow region is still open") end
    if underlined then throw_parse_error("reached end of text, but effect underlined region is still open") end
    if strikethrough then throw_parse_error("reached end of text, but effect strikethrough region is still open") end
    if is_outlined then throw_parse_error("reached end of text, but effect outline region is still open") end

    -- if all chars are visible or n visibile character not yet set
    if self._n_visible_characters == -1 or self._n_visible_characters == self._n_characters then
        self._n_visible_characters = self._n_characters
    else
        self:set_n_visible_characters(self._n_visible_characters)
    end

    if first_parse then
        -- automatically start animations only for labels that have an animated effect
        if animation_necessary then
            self:set_is_animated(true)
        end
    end
end

--- @brief [internal] calculate size given infinite area
function rt.Label:_update_default_size()
    self:size_allocate(0, 0, 2^32, 2^32)
    local min_x = POSITIVE_INFINITY
    local min_y = POSITIVE_INFINITY
    local max_x = NEGATIVE_INFINITY
    local max_y = NEGATIVE_INFINITY

    for _, glyph in pairs(self._glyphs) do
        if meta.isa(glyph, rt.Glyph) then
            local x, y = glyph:get_position()
            local w, h = glyph:get_size()

            min_x = math.min(min_x, x)
            min_y = math.min(min_y, y)
            max_x = math.max(max_x, x + w)
            max_y = math.max(max_y, y + h)
        end
    end
    self._default_width, self._default_height = max_x - min_x, max_y - min_y
    self._current_width = self._default_width
    self._current_height = self._default_height
end

--- @brief set text justification
--- @param mode rt.JustifyMode
function rt.Label:set_justify_mode(mode)
    if self._justify_mode ~= mode then
        self._justify_mode = mode
        self:reformat()
    end
end

--- @brief get text justification
--- @return rt.JustifyMode
function rt.Label:get_justify_mode()

    return self._justify_mode
end

--- @brief replace text and reformat
--- @param formatted_text String supports formatting tags
function rt.Label:set_text(formatted_text)

    self._raw = formatted_text
    self:_parse()
    self:_update_default_size()
    self:reformat()
end

--- @brief access raw text
--- @return String
function rt.Label:get_text()

    return self._raw;
end

--- @brief replace font
--- @param font rt.Font
function rt.Label:set_font(font)

    self._font = font
    self:reformat();
end

--- @brief set number of visible characters, does not respect beats
--- @param n Number
function rt.Label:set_n_visible_characters(n)
    local n_left = clamp(n, 0, self._n_characters)
    local n_glyphs = sizeof(self._glyphs)
    local glyph_i = 1
    local n_visible = 0

    while glyph_i <= n_glyphs do
        local glyph = self._glyphs[glyph_i]
        if meta.isa(glyph, rt.Glyph) then
            local n_chars = glyph:get_n_characters()
            if n_left >= n_chars then
                glyph:set_n_visible_characters(n_chars)
                n_left = n_left - n_chars
                n_visible = n_visible + n_chars
            else
                glyph:set_n_visible_characters(n_left)
                n_visible = n_visible + n_left
                n_left = 0
            end
        end
        glyph_i = glyph_i + 1
    end

    self._n_visible_characters = n_visible
end

--- @brief calculaten visible characters from scroll speed, respects beats and pauses on punctuation
function rt.Label:update_n_visible_characters_from_elapsed(elapsed, letters_per_second)
    local step = 1 / letters_per_second
    local n_letters = math.floor(elapsed / step)
    local so_far = 0
    local glyph_i = 1
    local n_visible = 0
    local beat_weight = rt.Label._syntax.BEAT_WEIGHTS[rt.Label._syntax.BEAT]
    local already_done_scrolling = false

    local weights = rt.Label._syntax.BEAT_WEIGHTS
    local beat_character = rt.Label._syntax.BEAT


    while glyph_i <= #self._glyphs and so_far < elapsed do
        local glyph = self._glyphs[glyph_i]
        if meta.isa(glyph, rt.Glyph) then
            if already_done_scrolling then
                glyph:set_n_visible_characters(0)
            else
                local text = glyph:get_content()
                local n_seen = 1
                for i = 1, #text do
                    local weight = weights[string.at(text, i)]
                    if weight == nil then
                        so_far = so_far + step
                    else
                        so_far = so_far + weight * step
                    end

                    if so_far > elapsed then
                        already_done_scrolling = false -- mark so all subsequent glyphs can be skipped
                        break
                    end
                    n_visible = n_visible + 1
                    n_seen = n_seen + 1
                end
                glyph:set_n_visible_characters(n_seen)
            end
        elseif glyph == weights then
            so_far = so_far + beat_weight * step
        end
        glyph_i = glyph_i + 1
    end

    return n_visible >= self._n_characters
end

--- @brief
function rt.Label:set_opacity(alpha)
    self._opacity = alpha
end

--- @brief
function rt.Label:get_n_visible_characters()
    return self._n_visible_characters
end

--- @brief set whether the glyphs of the label are animated
--- @param b Boolean
function rt.Label:set_is_animated(b)
    self._is_animated = b
    for _, glyph in pairs(self._glyphs) do
        if meta.isa(glyph, rt.Glyph) then
            glyph:set_is_animated(b)
        end
    end
end

--- @brief get whether the glyphs of the label are animated
--- @return Boolean
function rt.Label:get_is_animated()
    return self._is_animated
end

--- @brief get font
--- @retun rt.Font
function rt.Label:get_font()
    return self._font
end

--- @brief
function rt.Label:get_default_size()
    if not self:get_is_realized() then self:realize() end
    return self._default_width, self._default_height
end

--- @brief
function rt.Label:get_n_characters()
    return self._n_characters
end

--- @brief
function rt.Label:get_n_lines()
    return self._n_rows
end

--- @brief
function rt.Label:get_line_height()
    return self._font:get_bold_italic():getHeight()
end

--- @brief [internal]
function rt.test.label()
    error("TODO")
end