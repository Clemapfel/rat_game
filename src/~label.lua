--- class JustifyMode
rt.JustifyMode = meta.new_enum({
    LEFT = "left",
    RIGHT = "right",
    CENTER = "center"
    -- JUSTIFY = "justify"
})

--- @class rt.Label
rt.Label = meta.new_type("Label", function(text)
    if not meta.is_nil(text) then
        meta.assert_string(text)
    end

    local out = meta.new(rt.Label, {
        _glyph_rows = {},
        _glyph_row_widths = {},
        _glyph_row_height = {},
        _raw = "",
        _width = POSITIVE_INFINITY,
        _height = 0,
        _font = rt.Font.DEFAULT,
        _justify_mode = rt.JustifyMode.LEFT
    }, rt.Widget, rt.Drawable)
    out:set_text(text)
    return out
end)

--- @brief [internal]
function rt.Label:_apply_wrapping(width)
    meta.assert_isa(self, rt.Label)
    meta.assert_number(width)

    self._glyph_rows = {}
    local wrapped = {}
    for _, line in pairs(string.split(self._raw, "\n")) do
        local _, lines = self._font:get_regular():getWrap(line, width)
        for _, split_line in pairs(lines) do
            split_line = string.gsub(split_line, "\n", "")
            table.insert(wrapped, split_line)
        end
    end

    local row_i = 1
    local glyph_count = 0
    for _, line in pairs(wrapped) do
        self._glyph_rows[row_i] = {}
        self._glyph_row_widths[row_i] = 0
        self._glyph_row_height[row_i] = NEGATIVE_INFINITY
        local stripped = string.gsub(line, '^%s*(.-)%s*$', '%1') -- strip trailing whitespace
        local split = string.split(stripped, " ")
        for i, glyph in ipairs(split) do
            if i < #split then
                glyph = glyph .. " "
            end
            local to_push = rt.Glyph(self._font, glyph)
            table.insert(self._glyph_rows[row_i], to_push)
            local glyph_w, glyph_h = to_push:get_size()
            self._glyph_row_widths[row_i] = self._glyph_row_widths[row_i] + glyph_w
            self._glyph_row_height[row_i] = math.max(self._glyph_row_height[row_i], glyph_h)
            glyph_count = glyph_count + 1
        end
        row_i = row_i + 1
    end
end

--- @brief
function rt.Label:set_text(text)
    meta.assert_isa(self, rt.Label)
    if self._raw == text then return end
    
    self._raw = text

    if #self._raw ~= 0 then
        self:_apply_wrapping()
    end
end


--- @overload rt.Widget.size_allocate
function rt.Label:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.Label)

    local bounds_w, bounds_h = self:measure()
    self:_apply_wrapping(width)

    local row_x = x
    local row_y = y

    if self:get_horizontal_alignment() == rt.Alignment.START then
        -- noop
    elseif self:get_horizontal_alignment() == rt.Alignment.CENTER then
        row_x = row_x + 0.5 * width - 0.5 * bounds_w
    elseif self:get_horizontal_alignment() == rt.Alignment.END then
        row_x = row_x + width - bounds_w
    end

    if self:get_vertical_alignment() == rt.Alignment.START then
        -- noop
    elseif self:get_vertical_alignment() == rt.Alignment.CENTER then
        row_y = row_y + 0.5 * height - 0.5 * bounds_h
    elseif self:get_vertical_alignment() == rt.Alignment.END then
        row_y = row_y + height - bounds_h
    end

    for row_i, row in pairs(self._glyph_rows) do
        local offset = 0
        local line_height = NEGATIVE_INFINITY
        local row_w = self._glyph_row_widths[row_i]

        for i, glyph in pairs(row) do
            local w, h = glyph:get_size()
            local glyph_x = row_x + offset

            if self._justify_mode == rt.JustifyMode.LEFT then
                -- noop
            elseif self._justify_mode == rt.JustifyMode.CENTER then
                glyph_x = glyph_x + 0.5 * (self._width - row_w)
            elseif self._justify_mode == rt.JustifyMode.RIGHT then
                glyph_x = glyph_x + (self._width - row_w)
            end

            glyph:set_position(glyph_x, row_y)
            offset = offset + w
            line_height = math.max(line_height, h)
        end
        row_y = row_y + line_height
    end
end

--- @overload rt.Widget.measure
function rt.Label:measure()
    meta.assert_isa(self, rt.Label)
    local max_width = NEGATIVE_INFINITY
    local height = 0
    for i, width in ipairs(self._glyph_row_widths) do
        max_width = math.max(max_width, width)
        height = height + self._glyph_row_height[i]
    end
    return max_width, height
end

--- @brief
function rt.Label:set_justify_mode(mode)
    meta.assert_isa(self, rt.Label)
    meta.assert_enum(mode, rt.JustifyMode)
    self._justify_mode = mode
    self:reformat()
end

--- @class Label
rt.Label = meta.new_type("Label", function(formatted_text)
    local out = meta.new(rt.Label, {
        _glyph_rows = {},
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
    local glyphs = self._glyph_rows
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
    for _, glyph in pairs(self._glyph_rows) do
        glyph:draw()
    end
end
