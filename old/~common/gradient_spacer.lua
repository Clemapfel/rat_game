--- @class rt.GradientSpacer
rt.GradientSpacer = meta.new_type("GradientSpacer", rt.Widget, function(direction, color_from, color_to)
    return meta.new(rt.GradientSpacer, {
        _gradient = rt.Gradient(0, 0, 1, 1, color_from, color_to, direction)
    }, rt.Widget, rt.Drawable)
end)

--- @overload
function rt.GradientSpacer:size_allocate(x, y, width, height)
    self._gradient:resize(x, y, width, height)
end

--- @overload
function rt.GradientSpacer:draw()
    self._gradient:draw()
end

--- @brief test Spacer
function rt.test.spacer()
    error("TODO")
end
