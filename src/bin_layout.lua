--- @class rt.BinLayout
--- @brief Single-child container that assumes the dimensions of its singular child
rt.BinLayout = meta.new_type("BinLayout", function()
    local out = meta.new(rt.BinLayout, {
        _child = {}
    }, rt.Drawable, rt.Widget)
    return out
end)

--- @brief set singular child
--- @param child rt.Widget
function rt.BinLayout:set_child(child)
    meta.assert_isa(self, rt.BinLayout)
    meta.assert_isa(child, rt.Widget)

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
    meta.assert_isa(self, rt.BinLayout)
    return self._child
end

--- @brief remove child
function rt.BinLayout:remove_child()
    meta.assert_isa(self, rt.BinLayout)
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @overload rt.Drawable.draw
function rt.BinLayout:draw()
    meta.assert_isa(self, rt.BinLayout)
    if self:get_is_visible() and meta.is_widget(self._child) then
        self._child:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.BinLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.BinLayout)
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

