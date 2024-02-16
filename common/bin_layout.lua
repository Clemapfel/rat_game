--- @class rt.BinLayout
--- @brief Single-child container that assumes the dimensions of its singular child
rt.BinLayout = meta.new_type("BinLayout", rt.Widget, function()
    local out = meta.new(rt.BinLayout, {
        _child = {}
    })
    return out
end)

--- @brief set singular child
--- @param child rt.Widget
function rt.BinLayout:set_child(child)
    if not meta.is_nil(self._child) and meta.is_widget(self._child) then
        self._child:set_parent(nil)
    end

    self._child = child
    child:set_parent(self)

    if self:get_is_realized() then
        self._child:realize()
        self:reformat()
    end
end

--- @brief get singular child
--- @return rt.Widget
function rt.BinLayout:get_child()
    return self._child
end

--- @brief remove child
function rt.BinLayout:remove_child()
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @overload rt.Drawable.draw
function rt.BinLayout:draw()
    if self:get_is_visible() and meta.is_widget(self._child) then
        self._child:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.BinLayout:size_allocate(x, y, width, height)
    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x, y, width, height))
    end
end

--- @overload rt.Widget.measure
function rt.BinLayout:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.BinLayout:realize()

    if self:get_is_realized() then return end

    self._realized = true
    if meta.is_widget(self._child) then
        self._child:realize()
    end
end

--- @brief test BinLayout
function rt.test.bin_layout()
    error("TODO")
end

