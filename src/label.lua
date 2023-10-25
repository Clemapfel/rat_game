---@class JustifyMode
rt.JustifyMode = meta.new_enum({
    LEFT = "left",
    RIGHT = "right",
    CENTER = "center"
})

--- @class rt.Label
rt.Label = meta.new_type("Label", function(text)
    meta.assert_string(text)

    local out = meta.new(rt.Label, {
        _raw = text,
        _font = rt.Font.DEFAULT,
        _justify_mode = rt.JustifyMode.LEFT,
        _glyphs = {}
    }, rt.Widget, rt.Drawable)
    out:_parse()
    return out
end)

--- @overload rt.Drawable.draw
function rt.Label:draw()
    meta.assert_isa(self, rt.Label)
    for _, glyph in pairs(self._glyphs) do
        if meta.isa(glyph, rt.Glyph) then
            glyph:draw()
        end
    end
end

--- @overload rt.Widget.size_allocate
function rt.Label:size_allocate(x, y, width, height)

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

rt.Label.SPACE = " "
rt.Label.NEWLINE = "\n"
rt.Label.TAB = "    "

--- @brief [internal]
function rt.Label:_parse()
    meta.assert_isa(self, rt.Label)

    self._glyphs = {}

    local bold = false
    local italic = false

    local current_word = ""

    local i = 1
    local s = string.sub(self._raw, 1, 1)

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

        println("push: ", current_word)

        table.insert(self._glyphs, rt.Glyph(self._font, current_word, style))
        current_word = ""
    end

    local function step()
        i = i + 1
        s = string.sub(self._raw, i, i)
    end

    while i < #self._raw do
        if s == " " then
            table.insert(self._glyphs, rt.Label.SPACE)
            push_glyph()
        elseif s == "\n" then
            table.insert(self._glyphs, rt.Label.NEWLINE)
            push_glyph()
        elseif s == "\t" then
            table.insert(self._glyphs, rt.Label.TAB)
            push_glyph()
        else
            current_word = current_word .. s
        end
        step()
    end
    push_glyph()
end

