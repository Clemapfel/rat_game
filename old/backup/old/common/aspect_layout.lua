--- @class rt.AspectLayout
--- @brief Makes sure its singular child conforms to given width-to-height ratio
--- @param ratio Number
--- @param child rt.Widget (or nil)
rt.AspectLayout = meta.new_type("AspectLayout", rt.Widget, function(ratio, child)
    local out = meta.new(rt.AspectLayout, {
        _child = {},
        _ratio = ratio
    })

    if not meta.is_nil(child) then
        out:set_child(child)
    end
    return out
end)

--- @brief set singular child
--- @param child rt.Widget
function rt.AspectLayout:set_child(child)
    self._child = child
    if self._is_realized == true then
        child:realize()
        self:reformat()
    end
end

--- @brief get singular child
--- @return rt.Widget
function rt.AspectLayout:get_child()
    return self._child
end

--- @brief remove child
function rt.AspectLayout:remove_child()
    if meta.is_widget(self._child) then
        self._child = {}
    end
end

--- @overload rt.Drawable.draw
function rt.AspectLayout:draw()
    if self:get_is_visible() and meta.is_widget(self._child) then
        self._child:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.AspectLayout:size_allocate(x, y, width, height)
    if not meta.is_widget(self._child) then return end

    local child_x, child_y, child_w, child_h
    if height < width then
        child_h = height
        child_w = height * self._ratio
    else
        child_w = width
        child_h = width / self._ratio
    end

    child_x = x + (width - child_w) / 2
    child_y = y + (height - child_h) / 2

    if meta.is_widget(self._child) then
        self._child:fit_into(child_x, child_y, child_w, child_h)
    end
end

--- @overload rt.Widget.measure
function rt.AspectLayout:measure()
    if not meta.is_widget(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.AspectLayout:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    if meta.is_widget(self._child) then
        self._child:realize()
    end
    self:reformat()
end

--- @brief
function rt.AspectLayout:set_opacity(alpha)
    self._opacity = alpha
    if meta.is_widget(self._child) then
        self._child:set_opacity(alpha)
    end
end