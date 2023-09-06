--- @class AllocationHandler
rt.AllocationHandler = {}

--- @class Alignment
rt.Alignment = meta.new_enum({
    START = 0,
    CENTER = 1,
    END = 2
})

--- @class AllocationComponent
--- @signal changed (::AllocationComponent, x::Number, y::Number, width::Number, height::Number) -> nil
rt.AllocationComponent = meta.new_type("AllocationComponent", function(holder)
    local out = meta.new(rt.AllocationComponent, {
        _instance = holder,
        _bounds = rt.Rectangle(),
        _margins = {
            top = 0,
            right = 0,
            bottom = 0,
            left = 0
        },
        _expand_horizontally = true,
        _expand_vertically = true,
        _horizontal_alignment = rt.Alignment.CENTER,
        _vertical_alignment = rt.Alignment.CENTER
    })

    rt.add_signal_component(out)
    out.signal:add("changed")
    return out
end)

function rt.AllocationHandler._emit_changed(self)
    meta.assert_isa(self, rt.AllocationComponent)
    local new_bounds = self:get_bounds()
    self.signal:emit("changed", new_bounds.x, new_bounds.y, new_bounds.width, new_bounds.height)
end

--- @brief move by offset
--- @param self AllocationComponent
--- @param x_offset Number
--- @param y_offset Number
function rt.AllocationComponent.move(self, x_offset, y_offset)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_number(x_offset, y_offset)
    self._bounds.x = self._bounds.x + x_offset
    self._bounds.y = self._bounds.y + y_offset
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set top left
--- @param self AllocationComponent
--- @param x Number
--- @param y Number
function rt.AllocationComponent.set_position(self, x, y)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_number(x, y)
    self._bounds.x = x
    self._bounds.y = y
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set width, height
--- @param self AllocationComponent
--- @param x Number
--- @param y Number
function rt.AllocationComponent.set_size(self, width, height)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_number(width, height)
    self._bounds.width = width
    self._bounds.height = height
    rt.AllocationHandler._emit_changed(self)
end

--- @brief get axis aligned bounding box
--- @param self AllocationComponent
--- @return Rectangle
function rt.AllocationComponent.get_bounds(self)
    meta.assert_isa(self, rt.AllocationComponent)
    local out = rt.Rectangle()
    out.x = self._bounds.x - self._margins.left
    out.y = self._bounds.y - self._margins.top
    out.width = self._bounds.width + self._margins.left + self._margins.right
    out.height = self._bounds.height + self._margins.top + self._margins.bottom
    return out
end

--- @brief get top left
--- @param self AllocationComponent
--- @return (Number, Number)
function rt.AllocationComponent.get_position(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self:get_bounds():get_top_left()
end

--- @brief get width, height
--- @param self AllocationComponent
--- @return (Number, Number)
function rt.AllocationComponent.get_size(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self:get_bounds():get_size()
end

--- @brief [internal] assert that margin is non-negative
--- @param value Number
--- @param scope String
function rt.AllocationComponent._assert_margin(value, scope)
    meta.assert_number(value)
    if value < 0 then
        error("[rt] In " .. scope .. ": Margin `" .. tostring(value) .. "` cannot be negative")
    end
end

--- @brief set margin start
--- @param self AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_left(self, value)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(value, "AllocationComponent.set_margin_left")
    self._bounds._margins.left = value
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set margin end
--- @param self AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_right(self, value)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(value, "AllocationComponent.set_margin_right")
    self._bounds._margins.right = value
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set margin top
--- @param self AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_top(self, value)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(value, "AllocationComponent.set_margin_left")
    self._bounds._margins.top = value
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set margin bottom
--- @param self AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_bottom(self, value)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(value, "AllocationComponent.set_margin_bottom")
    self._bounds._margins.bottom = value
    rt.AllocationHandler._emit_changed(self)
end

--- @brief get margin start
--- @param self AllocationComponent
--- @return Number
function rt.AllocationComponent.get_margin_left(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._bounds._margins.left
end

--- @brief get margin end
--- @param self AllocationComponent
--- @return Number
function rt.AllocationComponent.get_margin_right(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._bounds._margins.right
end

--- @brief get margin top
--- @param self AllocationComponent
--- @return Number
function rt.AllocationComponent.get_margin_top(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._bounds._margins.top
end

--- @brief get margin bottom
--- @param self AllocationComponent
--- @return Number
function rt.AllocationComponent.get_margin_bottom(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._bounds._margins.bottom
end

--- @brief set margin start and end
--- @param self AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_horizontal(self, both)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(both, "AllocationComponent.set_margin_horizontal")
    self._bounds._margins.left = both
    self._bounds._margins.right = both
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set margin top and bottom
--- @param self AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_vertical(self, both)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(both, "AllocationComponent.set_margin_vertical")
    self._bounds._margins.top = both
    self._bounds._margins.bottom = both
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set margin start, end, top, and bottom
--- @param self AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin(self, all)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(all, "AllocationComponent.set_margin")
    self._margins.top = all
    self._margins.bottom = all
    self._margins.left = all
    self._margins.right = all
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set whether object should expand along the x-axis
--- @param self AllocationComponent
--- @param b Boolean
function rt.AllocationComponent.set_expand_horizontally(self, b)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_boolean(b)
    self._expand_horizontally = b
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set whether object should expand along the y-axis
--- @param self AllocationComponent
--- @param b Boolean
function rt.AllocationComponent.set_expand_vertically(self, b)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_boolean(b)
    self._expand_vertically = b
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set whether object should expand along both axes
--- @param self AllocationComponent
--- @param b Boolean
function rt.AllocationComponent.set_expand(self, b)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_boolean(b)
    self._expand_horizontally = b
    self._expand_vertically = b
    rt.AllocationHandler._emit_changed(self)
end

--- @brief get whether object should expand along the x-axis
--- @param self AllocationComponent
--- @return Boolean
function rt.AllocationComponent.get_expand_horizontally(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._expand_horizontally
end

--- @brief get whether object should expand along the x-axis
--- @param self AllocationComponent
--- @return Boolean
function rt.AllocationComponent.get_expand_vertically(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._expand_vertically
end

--- @brief set alignment along the x-axis
--- @param self AllocationComponent
--- @param alignment Alignment
function rt.AllocationComponent.set_horizontal_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_enum(alignment, rt.Alignment)
    self._horizontal_alignment = alignment
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set alignment along the y-axis
--- @param self AllocationComponent
--- @param alignment Alignment
function rt.AllocationComponent.set_vertical_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_enum(alignment, rt.Alignment)
    self._vertical_alignment = alignment
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set alignment along both axes
--- @param self AllocationComponent
--- @param alignment Alignment
function rt.AllocationComponent.set_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_enum(alignment, rt.Alignment)
    self._horizontal_alignment = alignment
    self._vertical_alignment = alignment
    rt.AllocationHandler._emit_changed(self)
end

--- @brief set alignment along the x-axis
--- @param self AllocationComponent
--- @return Alignment
function rt.AllocationComponent.get_horizontal_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._horizontal_alignment
end

--- @brief set alignment along the y-axis
--- @param self AllocationComponent
--- @return Alignment
function rt.AllocationComponent.get_vertical_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._vertical_alignment
end

--- @brief [internal] test allocation component
function rt.test.allocation_component()
    local instance = meta._new("Object")
    instance.allocation = rt.AllocationComponent(instance)

    local x, y = instance.allocation:get_position()
    assert(x == 0 and y == 0)
    local width, height = instance.allocation:get_size()
    assert(width == 0 and height == 0)

    instance.allocation:set_position(1, 2)
    instance.allocation:set_size(3, 4)
    x, y = instance.allocation:get_position()
    assert(x == 1 and y == 2)
    width, height = instance.allocation:get_size()
    assert(width == 3 and height == 4)

    instance.allocation:set_margin(10)
    width, height = instance.allocation:get_size()
    assert(width == 3 + 20 and height == 4 + 20)
end
rt.test.allocation_component()
