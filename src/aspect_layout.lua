--- @class rt.AspectLayout
--- @brief Makes sure its singular child conforms to given width-to-height ratio
--- @param ratio Number
rt.AspectLayout = meta.new_type("AspectLayout", function(ratio)
    meta.assert_number(ratio)
    local out = meta.new(rt.AspectLayout, {
        _child = {},
        _ratio = ratio,
        _width = 0,
        _height = 0
    }, rt.Widget, rt.Drawable)
    return out
end)

--- @brief set singular child
--- @param child rt.Widget
function rt.AspectLayout:set_child(child)
    meta.assert_isa(self, rt.AspectLayout)
    meta.assert_isa(self, rt.Widget)

    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
    end

    self._child = child
    child:set_parent(self)

    if self:get_is_realized() then
        child:realize()
        self:reformat()
    end
end

--- @brief get singular child
--- @return rt.Widget
function rt.AspectLayout:get_child()
    meta.assert_isa(self, rt.AspectLayout)
    return self._child
end

--- @brief remove child
function rt.AspectLayout:remove_child()
    meta.assert_isa(self, rt.AspectLayout)
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @overload rt.Drawable.draw
function rt.AspectLayout:draw()
    meta.assert_isa(self, rt.AspectLayout)
    if self:get_is_visible() and not meta.is_nil(self._child) then
        self._child:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.AspectLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.AspectLayout)
    self._width = width
    self._height = height
    if meta.is_nil(self._child) then return end

    local child_x, child_y, child_w, child_h
    if height < width then
        child_h = height
        child_w = height * self._ratio
    else
        child_w = width
        child_h = width / self._ratio
    end

    local child_x = x + (width - child_w) / 2
    local child_y = y + (height - child_h) / 2

    self._child:fit_into(rt.AABB(child_x, child_y, child_w, child_h))
end

--- @overload rt.Widget.measure
function rt.AspectLayout:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.AspectLayout:realize()
    local should_reformat = self:get_is_realized() == false

    self._realized = true

    if meta.isa(self._child, rt.Widget) then
        self._child:realize()
    end

    if should_reformat then self:reformat() end
end

--- @brief test AspectLayout
function rt.test.aspect_layout()
    error("TODO")
end

