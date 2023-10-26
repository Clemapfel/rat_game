---@class rt.JustifyMode
rt.JustifyMode = meta.new_enum({
    LEFT = "left",
    RIGHT = "right",
    CENTER = "center",
    BLOCK = "justify",
})

--- @class rt.Label
rt.Label = meta.new_type("Label", function(text)
    meta.assert_string(text)
    local out = meta.new(rt.Label, {
        _raw = text,
        _font = rt.Font.DEFAULT,
        _justify_mode = rt.JustifyMode.BLOCK,
        _glyphs = {}
    }, rt.Widget, rt.Drawable)
    out:_parse()
    return out
end)

--- @overload rt.Drawable.draw
function rt.Label:draw()
    meta.assert_isa(self, rt.Label)

    if not self:get_is_visible() then return end
    for _, glyph in pairs(self._glyphs) do
        if meta.isa(glyph, rt.Glyph) then
            glyph:draw()
        end
    end
end

--- @overload rt.Widget.size_allocate
function rt.Label:size_allocate(x, y, width, height)

    local space = self._font:get_bold_italic():getWidth(rt.Label.SPACE)
    local tab = self._font:get_bold_italic():getWidth(rt.Label.TAB)
    local line_height = self._font:get_bold_italic():getHeight()

    local glyph_x = x
    local glyph_y = y

    local row_widths = {0}
    local rows = {{}}
    local row_i = 1
    local line_width = 0

    for _, glyph in pairs(self._glyphs) do
        if glyph == rt.Label.SPACE then
            glyph_x = glyph_x + space
            line_width = line_width + space
            table.insert(rows[row_i], rt.Label.SPACE)
        elseif glyph == rt.Label.TAB then
            glyph_x = glyph_x + tab
            line_width = line_width + tab
            table.insert(rows[row_i], rt.Label.TAB)
        elseif glyph == rt.Label.NEWLINE then
            glyph_x = x
            glyph_y = glyph_y + line_height

            row_widths[row_i] = line_width
            line_width = 0
            row_i = row_i + 1
            rows[row_i] = {}
        else
            local w, h = glyph:get_size()
            if glyph_x - x + w >= width then
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

    if self._justify_mode == rt.JustifyMode.LEFT then
        return
    elseif self._justify_mode == rt.JustifyMode.CENTER or self._justify_mode == rt.JustifyMode.RIGHT then
        for i, row in ipairs(rows) do
            for _, glyph in ipairs(rows[i]) do
                if meta.isa(glyph, rt.Glyph) then
                    local position_x, position_y = glyph:get_position()
                    if self._justify_mode == rt.JustifyMode.CENTER then
                        glyph:set_position(position_x + (width - row_widths[i]) * 0.5, position_y)
                    elseif self._justify_mode == rt.JustifyMode.RIGHT then
                        glyph:set_position(position_x + (width - row_widths[i]), position_y)
                    end
                end
            end
        end
    elseif self._justify_mode == rt.JustifyMode.BLOCK then
        -- calculate free space per line, then distribute evenly into spaces between words
        for i, row in ipairs(rows) do
            if sizeof(row) == 0 then goto continue end
            local free_space = width - row_widths[i]
            if free_space <= 0 then goto continue end

            local n_spaces = 0
            for _, glyph in ipairs(rows[i]) do
                if glyph == rt.Label.SPACE then
                    free_space = free_space + space
                    n_spaces = n_spaces + 1
                elseif glyph == rt.Label.TAB then
                    free_space = free_space + tab
                    n_spaces = n_spaces + 1
                end
            end

            local row_x, row_y = rows[i][1]:get_position()
            local space_increment = free_space / (n_spaces + 1)
            for _, glyph in ipairs(rows[i]) do
                if meta.isa(glyph, rt.Glyph) then
                    glyph:set_position(row_x, row_y)
                    row_x = row_x + glyph:get_size() + space_increment
                end
            end
            ::continue::
        end
    end
end

--- @overload rt.Widget.measure
function rt.Label:measure()
    meta.assert_isa(self, rt.Label)

    local min_x = POSITIVE_INFINITY
    local min_y = POSITIVE_INFINITY
    local max_x = NEGATIVE_INFINITY
    local max_y = NEGATIVE_INFINITY

    for _, glyph in pairs(self._glyphs) do
        local x, y = glyph:get_position()
        local w, h = glyph:get_size()

        min_x = math.min(min_x, x)
        min_y = math.min(min_y, y)
        max_x = math.max(max_x, x + w)
        max_y = math.max(max_y, y + h)
    end

    return max_x - min_x, max_y - min_y
end

-- control characters used for wrap hinting
rt.Label.SPACE = " "
rt.Label.NEWLINE = "\n"
rt.Label.TAB = "    "
rt.Label.ESCAPE_CHARACTER = "%"

-- regex patterns to match tags
rt.Label.BOLD_TAG_START = rt.Set("<b>", "<bold>")
rt.Label.BOLD_TAG_END = rt.Set("</b>", "</bold>")
rt.Label.ITALIC_TAG_START = rt.Set("<i>", "<italic>")
rt.Label.ITALIC_TAG_END = rt.Set("</i>", "</italic>")
rt.Label.COLOR_TAG_START = rt.Set("<col=(.*)>", "<color=(.*)>")
rt.Label.COLOR_TAG_END = rt.Set("</col>", "</color>")
rt.Label.EFFECT_SHAKE_TAG_START = rt.Set("<shake>", "<fx_shake>")
rt.Label.EFFECT_SHAKE_TAG_END = rt.Set("</shake>", "</fx_shake>")
rt.Label.EFFECT_WAVE_TAG_START = rt.Set("<wave>", "<fx_wave>")
rt.Label.EFFECT_WAVE_TAG_END = rt.Set("</wave", "</fx_wave>")
rt.Label.EFFECT_RAINBOW_TAG_START = rt.Set("<rainbow>", "<fx_rainbow>")
rt.Label.EFFECT_RAINBOW_TAG_END = rt.Set("</rainbow>", "</fx_rainbow>")

--- @brief [internal]
function rt.Label:_parse()
    meta.assert_isa(self, rt.Label)

    self._glyphs = {}

    local bold = false
    local italic = false
    local is_colored = false
    local color = "PURE_WHITE"

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

        local effects = {}
        if effect_rainbow then table.insert(effects, rt.TextEffect.RAINBOW) end
        if effect_shake then table.insert(effects, rt.TextEffect.SHAKE) end
        if effect_wave then table.insert(effects, rt.TextEffect.WAVE) end

        table.insert(self._glyphs, rt.Glyph(self._font, current_word, style, rt.Palette[color], effects))
        current_word = ""
    end

    -- throw error, with guides
    local function throw_parse_error(reason)
        meta.assert_string(reason)
        error("[rt] In rt.Label._parse: Error at position `" .. tostring(i) .. "`: " .. reason)
    end

    -- advance n characters
    local function step(n)
        if meta.is_nil(n) then n = 1 end
        meta.assert_number(n)
        i = i + n
        s = string.sub(self._raw, i, i)
    end

    -- check if next `#tag` characters match `tag`
    local function tag_matches(tags)
        local sequence = ""
        local sequence_i = 0
        repeat
            if i + sequence_i > #self._raw then
                throw_parse_error("malformed tag, reached end of text")
            end
            local sequence_s = string.sub(self._raw, i + sequence_i, i + sequence_i)
            sequence = sequence .. sequence_s
            sequence_i = sequence_i + 1
        until sequence_s == ">"

        for tag in pairs(tags) do
            if not meta.is_nil(string.find(sequence, tag)) then
                step(#sequence)
                return true
            end
        end
        return false
    end

    -- test if upcoming control sequence matches rt.Label.COLOR_TAG_START
    local function is_color_tag()
        local sequence = ""
        local color_i = 0
        repeat
            if i + color_i > #self._raw then
                throw_parse_error("malformed color tag, reached end of text")
            end
            local color_s = string.sub(self._raw, i + color_i, i + color_i)
            sequence = sequence .. color_s
            color_i = color_i + 1
        until color_s == ">"

        for tag in pairs(rt.Label.COLOR_TAG_START) do
            local _, _, new_color = string.find(sequence, tag)
            if not meta.is_nil(new_color) then
                if not rt.is_rgba(rt.Palette[new_color]) then
                    throw_parse_error("malformed color tag: color `" .. new_color .. "` unknown")
                end
                color = new_color
                step(#sequence)
                return true
            end
        end
        return false
    end

    while i < #self._raw do
        if s == " " then
            push_glyph()
            table.insert(self._glyphs, rt.Label.SPACE)
        elseif s == "\n" then
            push_glyph()
            table.insert(self._glyphs, rt.Label.NEWLINE)
        elseif s == "\t" then
            push_glyph()
            table.insert(self._glyphs, rt.Label.TAB)
        elseif s == "<" then
            push_glyph()
            -- bold
            if tag_matches(rt.Label.BOLD_TAG_START) then
                if bold == true then
                    throw_parse_error("trying to open a bold region, but one is already open")
                end
                bold = true
            elseif tag_matches(rt.Label.BOLD_TAG_END) then
                if bold == false then
                    throw_parse_error("trying to close a bold region, but one is not open")
                end
                bold = false
            -- italic
            elseif tag_matches(rt.Label.ITALIC_TAG_START) then
                if italic == true then
                    throw_parse_error("trying to open an italic region, but one is already open")
                end
                italic = true
            elseif tag_matches(rt.Label.ITALIC_TAG_END) then
                if italic == false then
                    throw_parse_error("trying to close an italic region, but one is not open")
                end
                italic = false
            -- color
            elseif is_color_tag() then
                if is_colored == true then
                    throw_parse_error("trying to open a color region, but one is already open")
                end
                is_colored = true
            elseif tag_matches(rt.Label.COLOR_TAG_END) then
                if is_colored == false then
                    throw_parse_error("trying to close a color region, but one is not open")
                end
                is_colored = false
            -- effect: shake
            elseif tag_matches(rt.Label.EFFECT_SHAKE_TAG_START) then
                if effect_shake == true then
                    throw_parse_error("trying to open an effect shake region, but one is already open")
                end
                effect_shake = true
            elseif tag_matches(rt.Label.EFFECT_SHAKE_TAG_END) then
                if effect_shake == false then
                    throw_parse_error("trying to close an effect shake region, but one is not open")
                end
                effect_shake = false
            -- effect: wave
            elseif tag_matches(rt.Label.EFFECT_WAVE_TAG_START) then
                if effect_wave == true then
                    throw_parse_error("trying to open an effect wave region, but one is already open")
                end
                effect_wave = true
            elseif tag_matches(rt.Label.EFFECT_WAVE_TAG_END) then
                if effect_wave == false then
                    throw_parse_error("trying to close an effect wave region, but one is not open")
                end
                effect_wave = false
            -- effect: rainbow
            elseif tag_matches(rt.Label.EFFECT_RAINBOW_TAG_START) then
                if effect_rainbow == true then
                    throw_parse_error("trying to open an effect rainbow region, but one is already open")
                end
                effect_rainbow = true
            elseif tag_matches(rt.Label.EFFECT_RAINBOW_TAG_END) then
                if effect_rainbow == false then
                    throw_parse_error("trying to close an effect rainbow region, but one is not open")
                end
                effect_rainbow = false
            else -- unknown tag
                local sequence = ""
                local sequence_i = 0
                repeat
                    if i + sequence_i > #self._raw then
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
    if effect_shake then throw_parse_error("reached end of text, but effect shake region is still open") end
    if effect_wave then throw_parse_error("reached end of text, but effect wave region is still open") end
    if effect_rainbow then throw_parse_error("reached end of text, but effect rainbow region is still open") end
end

--- @brief
function rt.Label:set_justify_mode(mode)
    meta.assert_isa(self, rt.Label)
    meta.assert_enum(mode, rt.JustifyMode)

    if self._justify_mode ~= mode then
        self._justify_mode = mode
        self:reformat()
    end
end

--- @brief
function rt.Label:get_justify_mode()
    meta.assert_isa(self, rt.Label)
    return self._justify_mode
end

--- @brief
function rt.Label:set_text(formatted_text)
    meta.assert_isa(self, rt.Label)
    meta.assert_string(formatted_text)
    self._raw = formatted_text
    self:_parse()
    self:reformat()
end

--- @brief
function rt.Label:get_text()
    meta.assert_isa(self, rt.Label)
    return self._raw;
end

--- @brief
function rt.Label:set_font(font)
    meta.assert_isa(self, rt.Label)
    meta.assert_isa(font, rt.Font)
    self._font = font
    self:reformat();
end

