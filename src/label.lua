--- class TextAlignment
rt.TextAlignment = meta.new_enum({
    LEFT = "left",
    RIGHT = "right",
    CENTER = "center",
    JUSTIFY = "justify"
})

--- @class Label
rt.Label = meta.new_type("Label", function(text)
    if not meta.is_nil(text) then
        meta.assert_string(text)
    end

    local out = meta.new(rt.Label, {
        _glyphs = {},
        _raw = "",
        _width = POSITIVE_INFINITY,
        _height = 0,
        _font = rt.Font.DEFAULT,
        _text_alignment = rt.TextAlignment.LEFT
    }, rt.Widget, rt.Drawable)
    out:set_text(text)
    return out
end)

--- @brief
function rt.Label:_apply_wrapping()
    meta.assert_isa(self, rt.Label)
    self._glyphs = {}
    local wrapped = {}
    for _, line in pairs(string.split(self._raw, "\n")) do
        local _, lines = self._font:get_regular():getWrap(line, self._width)
        for _, split_line in pairs(lines) do
            --split_line = string.gsub(split_line, "\n", "")
            table.insert(wrapped, split_line)
        end
    end

    local row_i = 1
    for _, line in pairs(wrapped) do

        self._glyphs[row_i] = {}
        local stripped = string.gsub(line, '^%s*(.-)%s*$', '%1') -- strip trailing whitespace
        local split = string.split(stripped, " ")
        for i, glyph in ipairs(split) do
            if i < #split then
                glyph = glyph .. " "
            end
            table.insert(self._glyphs[row_i], rt.Glyph(self._font, glyph))
        end
        row_i = row_i + 1
    end
    self:reformat()
end

--- @brief
function rt.Label:set_text(text)
    meta.assert_isa(self, rt.Label)
    if self._raw == text then return end

    self._raw = text
    self:_apply_wrapping()
end

--- @overload rt.Drawable.draw
function rt.Label:draw()
    meta.assert_isa(self, rt.Label)
    for _, row in pairs(self._glyphs) do
        for _, glyph in pairs(row) do
            glyph:draw()
        end
    end
end

--- @overload rt.Widget.size_allocate
function rt.Label:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.Label)

    local should_wrap = self._width ~= width

    self._width = width
    self._height = height

    if should_wrap then self:_apply_wrapping() end

    local row_x = x
    local row_y = y
    for row_i, row in pairs(self._glyphs) do
        local offset = 0
        local line_height = NEGATIVE_INFINITY
        for _, glyph in pairs(row) do
            local w, h = glyph:get_size()

            local glyph_x
            if self._text_alignment == rt.TextAlignment.LEFT then
            elseif self._text_alignment == rt.TextAlignment.RIGHT then
            elseif self._text_alignment == rt.TextAlignment.CENTER then
            elseif self._text_alignment == rt.TextAlignment.JUSTIFY then
                -- TODO
            end

            glyph_x = row_x + offset

            glyph:set_position(glyph_x, row_y)
            offset = offset + w
            line_height = math.max(line_height, h)
        end
        row_y = row_y + line_height
    end
end

--- @overload rt.Widget.measure
function rt.Label:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return self._width, self._height
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
