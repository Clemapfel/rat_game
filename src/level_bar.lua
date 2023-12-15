rt.settings.level_bar = {
    backdrop_darken_offset = 0.3,
    corner_radius = rt.settings.margin_unit,
    outline_width = 3
}

--- @class rt.LevelBar
rt.LevelBar = meta.new_type("LevelBar", function(lower, upper, value)

    if meta.is_nil(value) then
        value = mix(lower, upper, 0.5)
    end

    meta.assert_number(upper)

    local out = meta.new(rt.LevelBar, {
        _lower = lower,
        _upper = upper,
        _value = value,
        _shape = rt.Rectangle(0, 0, 1, 1),
        _shape_outline = rt.Line(0, 0, 1, 1),   -- right edge of bar, to avoid overlap with `_backdrop_outline`
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _backdrop_outline = rt.Rectangle(0, 0, 1, 1),
        _color = rt.Palette.HIGHLIGHT,
        _backdrop_color = rt.color_darken(rt.Palette.HIGHLIGHT, rt.settings.level_bar.backdrop_darken_offset),
        _marks = {} -- {value, line}
    }, rt.Drawable, rt.Widget)

    out._backdrop_outline:set_is_outline(true)
    out._shape_outline:set_is_outline(true)

    out._backdrop_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    out._shape_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)

    out._backdrop_outline:set_line_width(rt.settings.level_bar.outline_width)
    out._shape_outline:set_line_width(1)

    for _, shape in pairs({out._backdrop, out._backdrop_outline}) do
        shape:set_corner_radius(rt.settings.level_bar.corner_radius)
    end

    out:set_color(out._color)
    out:_update_value()

    return out
end)

--- @brief [internal]
function rt.LevelBar:_update_value()
    local x, y = self._backdrop:get_position()
    local width, height = self._backdrop:get_size()
    local bounds = rt.AABB(x, y, ((self._value - self._lower) / (self._upper - self._lower)) * width, height)

    bounds = rt.AABB(math.round(bounds.x), math.round(bounds.y), math.round(bounds.width), math.round(bounds.height))
    self._shape:resize(bounds)
    self._shape_outline:resize(bounds.x + bounds.width, bounds.y, bounds.x + bounds.width, bounds.y + bounds.height)


    for _, mark in pairs(self._marks) do
        local mark_x = math.floor(x + (mark.value - self._lower) / (self._upper - self._lower) * width)
        mark.line = {mark_x, y, mark_x, y + height}
    end
end

--- @overload rt.Drawable.draw
function rt.LevelBar:draw()

    if not self:get_is_visible() then return end

    -- draw with rounded corners
    local stencil_value = 255
    love.graphics.stencil(function()
        self._backdrop:draw()
    end, "replace", stencil_value, true)
    love.graphics.setStencilTest("equal", stencil_value)

    self._backdrop:draw()
    self._shape:draw()

    -- draw marks with 1-px outline on each side
    local thickness = 2
    love.graphics.push()
    local outline_color = self._backdrop_outline:get_color()
    for _, mark in pairs(self._marks) do
        --[[
        love.graphics.setLineWidth(thickness)
        love.graphics.setColor(outline_color.r, outline_color.g, outline_color.b, outline_color.a)
        love.graphics.translate(-thickness, 0)
        love.graphics.line(table.unpack(mark.line))
        love.graphics.translate( 2 * thickness, 0)
        love.graphics.line(table.unpack(mark.line))
        love.graphics.translate(-thickness, 0)
        love.graphics.setColor(1, 1, 1, 1)
        ]]--
        love.graphics.setColor(outline_color.r, outline_color.g, outline_color.b, outline_color.a)
        love.graphics.setLineWidth(rt.settings.level_bar.outline_width)
        love.graphics.line(table.unpack(mark.line))
    end
    love.graphics.pop()

    self._backdrop_outline:draw()
    self._shape_outline:draw()

    love.graphics.stencil(function() end, "replace", 0, false) -- reset stencil value
    love.graphics.setStencilTest()
end

--- @overload rt.Widget.size_allocate
function rt.LevelBar:size_allocate(x, y, width, height)

    local w, h = width, height
    if not self:get_expand_vertically() then
        h = rt.settings.font.default_size
    end

    local bounds = rt.AABB(math.round(x), math.round(y), w, h)
    self._backdrop:resize(bounds)
    self._backdrop_outline:resize(bounds)
    self:_update_value()
end

--- @brief
function rt.LevelBar:set_value(x)
    self._value = clamp(x, self._lower, self._upper)
    self:_update_value()
end

--- @brief
function rt.LevelBar:get_value()
    return self._value
end

--- @brief
function rt.LevelBar:set_color(color, backdrop_color)
    self._color = color
    self._backdrop_color = ternary(meta.is_nil(backdrop_color), rt.color_darken(self._color, rt.settings.level_bar.backdrop_darken_offset), backdrop_color)

    self._shape:set_color(self._color)
    self._backdrop:set_color(self._backdrop_color)
end

--- @brief
function rt.LevelBar:add_mark(value)
    if value < self._lower or value  > self._upper then
        rt.error("In LevelBar:add_mark: value `" .. tostring(value) .. " is out of range for level bar with bounds `[", tostring(self._lower) .. ", " .. tostring(self._upper) .. "]")
    end

    local x, y = self._backdrop:get_position()
    local width, height = self._backdrop:get_size()
    local mark_x = x + (value - self._lower) / (self._upper - self._lower) * width
    table.insert(self._marks, {
        value = value,
        line = {mark_x, y, mark_x, y + height}
    })
end

--- @brief
function rt.LevelBar:clear_marks()
    self._marks = {}
end