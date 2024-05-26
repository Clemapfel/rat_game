rt.settings.selection_indicator = {
    width = 2,
    outline_width = 10,
    corner_radius = 5,
    alpha = 1
}

--- @class
rt.SelectionIndicator = meta.new_type("SelectionIndicator", rt.Widget, function()  
    return meta.new(rt.SelectionIndicator, {
        _x = 0,
        _y = 0,
        _width = 0,
        _height = 0
    })
end)

--- @override
function rt.SelectionIndicator:resize(other_widget)
    self._x, self._y = other_widget:get_position()
    self._width, self._height = other_widget:measure()
end

--- @override
function rt.SelectionIndicator:draw()
    local x, y, w, h = self._x, self._y, self._width, self._height
    local color = rt.Palette.BACKGROUND
    local width = 5
    local corner_radius = rt.settings.selection_indicator.corner_radius
    local alpha = rt.settings.selection_indicator.alpha
    love.graphics.setLineStyle("smooth")

    love.graphics.setColor(color.r, color.g, color.b, alpha)
    love.graphics.setLineWidth(width + 3)
    love.graphics.rectangle("line", x - width, y - width, w + 2 * width, h + 2 * width, corner_radius, corner_radius)

    color = rt.Palette.SELECTION
    love.graphics.setColor(color.r, color.g, color.b, alpha)
    love.graphics.setLineWidth(width)
    love.graphics.rectangle("line", x - width, y - width, w + 2 * width, h + 2 * width, corner_radius, corner_radius)
end
