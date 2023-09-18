--[[
--- @class rt.Alignment
rt.Alignment = meta.new_enum({
    START = "ALIGNMENT_START",
    CENTER = "ALIGNMENT_CENTER",
    END = "ALIGNMENT_END"
})

--- @class rt.AllocationComponent
--- @signal changed (::AllocationComponent, x::Number, y::Number, width::Number, height::Number) -> nil
rt.AllocationComponent = meta.new_type("AllocationComponent", function()
    local out = meta.new(rt.AllocationComponent)
    rt.add_signal_component(out)
    out.signal:add("changed")
    return out
end)

rt.AllocationCompoent_bounds = rt.AxisAlignedRectangle()
rt.AllocationCompoent_margins = {
    top = 0,
    right = 0,
    bottom = 0,
    left = 0
}
rt.AllocationCompoent_expand_horizontally = true
rt.AllocationCompoent_expand_vertically = true
rt.AllocationCompoent_horizontal_alignment = rt.Alignment.CENTER
rt.AllocationCompoent_vertical_alignment = rt.Alignment.CENTER
rt.AllocationCompoent_minimum_width = 0
rt.AllocationCompoent_minimum_height = 0

function rt.AllocationComponent._emit_changed(self)
    meta.assert_isa(self, rt.AllocationComponent)
    local new_bounds = self:get_bounds()
    self.signal:emit("changed", new_bounds.x, new_bounds.y, new_bounds.width, new_bounds.height)
end

--- @brief move by offset
--- @param self rt.AllocationComponent
--- @param x_offset Number
--- @param y_offset Number
function rt.AllocationComponent.move(self, x_offset, y_offset)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_number(x_offset, y_offset)
    self._bounds.x = self._bounds.x + x_offset
    self._bounds.y = self._bounds.y + y_offset
    self:_emit_changed()
end

--- @brief set top left
--- @param self rt.AllocationComponent
--- @param x Number
--- @param y Number
function rt.AllocationComponent.set_position(self, x, y)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_number(x, y)
    self._bounds.x = x
    self._bounds.y = y
    self:_emit_changed()
end

--- @brief set width, height
--- @param self rt.AllocationComponent
--- @param x Number
--- @param y Number
function rt.AllocationComponent.set_size(self, width, height)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_number(width, height)
    self._bounds.width = width
    self._bounds.height = height
    self:_emit_changed()
end

--- @brief get axis aligned bounding box including margin
--- @param self rt.AllocationComponent
--- @return rt.AxisAlignedRectangle
function rt.AllocationComponent.get_bounds(self)
    meta.assert_isa(self, rt.AllocationComponent)
    local out = rt.AxisAlignedRectangle()
    out.x = self._bounds.x - self._margins.left
    out.y = self._bounds.y - self._margins.top
    out.width = self._bounds.width + self._margins.left + self._margins.right
    out.height = self._bounds.height + self._margins.top + self._margins.bottom
    return out
end

--- @brief get top left
--- @param self rt.AllocationComponent
--- @return (Number, Number)
function rt.AllocationComponent.get_position(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self:get_bounds():get_top_left()
end

--- @brief get width, height
--- @param self rt.AllocationComponent
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
--- @param self rt.AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_left(self, value)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(value, "AllocationComponent.set_margin_left")
    self._margins.left = value
    self:_emit_changed()
end
rt.AllocationComponent.set_margin_start = rt.AllocationComponent.set_margin_left

--- @brief set margin end
--- @param self rt.AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_right(self, value)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(value, "AllocationComponent.set_margin_right")
    self._margins.right = value
    self:_emit_changed()
end
rt.AllocationComponent.set_margin_end = rt.AllocationComponent.set_margin_right

--- @brief set margin top
--- @param self rt.AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_top(self, value)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(value, "AllocationComponent.set_margin_left")
    self._margins.top = value
    self:_emit_changed()
end

--- @brief set margin bottom
--- @param self rt.AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_bottom(self, value)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(value, "AllocationComponent.set_margin_bottom")
    self._margins.bottom = value
    self:_emit_changed()
end

--- @brief get margin start
--- @param self rt.AllocationComponent
--- @return Number
function rt.AllocationComponent.get_margin_left(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._margins.left
end

--- @brief get margin end
--- @param self rt.AllocationComponent
--- @return Number
function rt.AllocationComponent.get_margin_right(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._margins.right
end

--- @brief get margin top
--- @param self rt.AllocationComponent
--- @return Number
function rt.AllocationComponent.get_margin_top(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._margins.top
end

--- @brief get margin bottom
--- @param self rt.AllocationComponent
--- @return Number
function rt.AllocationComponent.get_margin_bottom(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._margins.bottom
end

--- @brief set margin start and end
--- @param self rt.AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_horizontal(self, both)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(both, "AllocationComponent.set_margin_horizontal")
    self._margins.left = both
    self._margins.right = both
    self:_emit_changed()
end

--- @brief set margin top and bottom
--- @param self rt.AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin_vertical(self, both)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(both, "AllocationComponent.set_margin_vertical")
    self._margins.top = both
    self._margins.bottom = both
    self:_emit_changed()
end

--- @brief set margin start, end, top, and bottom
--- @param self rt.AllocationComponent
--- @param value Number cannot be negative
function rt.AllocationComponent.set_margin(self, all)
    meta.assert_isa(self, rt.AllocationComponent)
    rt.AllocationComponent._assert_margin(all, "AllocationComponent.set_margin")
    self._margins.top = all
    self._margins.bottom = all
    self._margins.left = all
    self._margins.right = all
    self:_emit_changed()
end

--- @brief set whether object should expand along the x-axis
--- @param self rt.AllocationComponent
--- @param b Boolean
function rt.AllocationComponent.set_expand_horizontally(self, b)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_boolean(b)
    self._expand_horizontally = b
    self:_emit_changed()
end

--- @brief set whether object should expand along the y-axis
--- @param self rt.AllocationComponent
--- @param b Boolean
function rt.AllocationComponent.set_expand_vertically(self, b)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_boolean(b)
    self._expand_vertically = b
    self:_emit_changed()
end

--- @brief set whether object should expand along both axes
--- @param self rt.AllocationComponent
--- @param both Boolean
function rt.AllocationComponent.set_expand(self, both)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_boolean(both)
    self._expand_horizontally = both
    self._expand_vertically = both
    self:_emit_changed()
end

--- @brief get whether object should expand along the x-axis
--- @param self rt.AllocationComponent
--- @return Boolean
function rt.AllocationComponent.get_expand_horizontally(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._expand_horizontally
end

--- @brief get whether object should expand along the x-axis
--- @param self rt.AllocationComponent
--- @return Boolean
function rt.AllocationComponent.get_expand_vertically(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._expand_vertically
end

--- @brief set alignment along the x-axis
--- @param self rt.AllocationComponent
--- @param alignment rt.Alignment
function rt.AllocationComponent.set_horizontal_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_enum(alignment, rt.Alignment)
    self._horizontal_alignment = alignment
    self:_emit_changed()
end

--- @brief set alignment along the y-axis
--- @param self rt.AllocationComponent
--- @param alignment rt.Alignment
function rt.AllocationComponent.set_vertical_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_enum(alignment, rt.Alignment)
    self._vertical_alignment = alignment
    self:_emit_changed()
end

--- @brief set alignment along both axes
--- @param self rt.AllocationComponent
--- @param alignment rt.Alignment
function rt.AllocationComponent.set_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_enum(alignment, rt.Alignment)
    self._horizontal_alignment = alignment
    self._vertical_alignment = alignment
    self:_emit_changed()
end

--- @brief set alignment along the x-axis
--- @param self rt.AllocationComponent
--- @return rt.Alignment
function rt.AllocationComponent.get_horizontal_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._horizontal_alignment
end

--- @brief set alignment along the y-axis
--- @param self rt.AllocationComponent
--- @return rt.Alignment
function rt.AllocationComponent.get_vertical_alignment(self, alignment)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._vertical_alignment
end

--- @brief request the object to have a minum size
--- @param self rt.AllocationComponent
--- @param minimum_width Number
--- @param minimum_height Number
function rt.AllocationComponent.set_minimum_size(self, minimum_width, minimum_height)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_number(minimum_width, minimum_height)
    self._minimum_width = minimum_width
    self._minimum_height = minimum_height
end

--- @brief access minimum size
--- @params self rt.AllocationComponent
--- @return (Number, Number) width, height
function rt.AllocationComponent.get_minimum_size(self)
    meta.assert_isa(self, rt.AllocationComponent)
    return self._minimum_width, self._minimum_height
end

--- @brief calculate minimum amount of space that the allocation needs
--- @return (Number, Number)
function rt.AllocationComponent.get_natural_size(self)
    meta.assert_isa(self, rt.AllocationComponent)

    local w = self._bounds.width + self._margins.left + self._margins.right
    local h = self._bounds.height + self._margins.top + self._margins.right
    return w, h
end

--- @brief [internal] calulcate size along one axis
--- @param self rt.AllocationComponent
--- @param width Number
--- @param margin_start Number
--- @param margin_end Number
--- @param align rt.Alignment
--- @param expand Boolean
--- @param range_start Number minimum x
--- @param range_size Number maximum width
--- @return (Number, Number) x, width
function rt.AllocationComponent._calculate_size(self, width, margin_start, margin_end, align, expand, range_start, range_size)
    meta.assert_isa(self, rt.AllocationComponent)
    meta.assert_number(width, margin_start, margin_end)
    meta.assert_enum(align, rt.Alignment)
    meta.assert_boolean(expand)

    local x = range_start
    local w = width
    local m0 = margin_start
    local m1 = margin_end
    local L = range_size
    
    if (w + m0 + m1) > L then
        print("[rt] In rt.AllocationComponent._calculate_size: Allocation of `" .. meta.typeof(self._instance) .. "` exceeds allocated area: `" .. tostring(w + m0 + m1) .. "` > `" .. tostring(L) .. "`\n")
    end

    if align == rt.Alignment.START and expand == false then
        return x + m0, w
    elseif align == rt.Alignment.CENTER and expand == false then
        return x + L - m1 - w - (L - m0 - m1 - w) / 2, w
    elseif align == rt.Alignment.END and expand == false then
        return x + L - m1 - w, w
    elseif align == rt.Alignment.START and expand == true then
        return x + m0, math.max(w, (L - m0 - m1) / 2)
    elseif align == rt.Alignment.CENTER and expand == true then
        return x + m0, math.max(w, L - m0 - m1)
    elseif align == rt.Alignment.END and expand == true then
        local w_out = math.max(w, (L - m0 - m1) / 2)
        return x + L - m1 - w_out, w_out
    else
        error("In rt.AllocationComponent._calculate_size: unreachable reached")
    end
end

--- @brief fit into rectangle, respecting margins
--- @param self rt.AllocationComponent
--- @param new_bounds rt.AxisAlignedRectangle
function rt.AllocationComponent.resize(self, new_bounds)
    meta.assert_isa(new_bounds, rt.AxisAlignedRectangle)

    local x, width = rt.AllocationComponent._calculate_size(self,
        math.max(self._bounds.width, self._minimum_width),
        self._margins.left,
        self._margins.right,
        self._horizontal_alignment,
        self._expand_horizontally,
        new_bounds.x,
        new_bounds.width
    )

    local y, height = rt.AllocationComponent._calculate_size(self,
        math.max(self._bounds.height, self._minimum_height),
        self._margins.top,
        self._margins.bottom,
        self._vertical_alignment,
        self._expand_vertically,
        new_bounds.y,
        new_bounds.height
    )
    
    self._bounds = rt.AxisAlignedRectangle(x, y, width, height)
end

--- @brief add an allocation component as `.allocation`
--- @param object meta.Object
function rt.add_allocation_component(object)
    meta.assert_object(object)

    if not meta.is_nil(object.allocation) then
        error("[rt] In add_allocation_component: Object of type `" .. meta.typeof(object) .. "` already has a member called `allocation`")
    end

    meta._install_property(object, "allocation", rt.AllocationComponent(object))
    return rt.get_allocation_component(object)
end

--- @brief get allocation component assigned
--- @param object meta.Object
--- @return rt.AllocationComponent
function rt.get_allocation_component(self)
    return self.allocation
end

--- @brief [internal] test allocation component
function rt.test.allocation_component()
    local instance = meta._new("Object")
    instance.allocation = rt.AllocationComponent(instance)

    local changed_called = 0
    instance.allocation.signal:connect("changed", function()
        changed_called = changed_called + 1
    end)

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

    instance.allocation:set_margin_left(10)
    instance.allocation:set_margin_right(10)
    instance.allocation:set_margin_top(10)
    instance.allocation:set_margin_bottom(10)

    width, height = instance.allocation:get_size()
    assert(width == 3 + 20 and height == 4 + 20)

    assert(instance.allocation:get_expand_horizontally() == true)
    assert(instance.allocation:get_expand_vertically() == true)
    instance.allocation:set_expand_horizontally(false)
    instance.allocation:set_expand_vertically(false)
    assert(instance.allocation:get_expand_horizontally() == false)
    assert(instance.allocation:get_expand_vertically() == false)

    assert(instance.allocation:get_horizontal_alignment() == rt.Alignment.CENTER)
    assert(instance.allocation:get_vertical_alignment() == rt.Alignment.CENTER)
    instance.allocation:set_horizontal_alignment(rt.Alignment.START)
    instance.allocation:set_vertical_alignment(rt.Alignment.END)
    assert(instance.allocation:get_horizontal_alignment() == rt.Alignment.START)
    assert(instance.allocation:get_vertical_alignment() == rt.Alignment.END)
    assert(changed_called == 10)

    -- todo: test .resize
end
rt.test.allocation_component()

]]--