--- @class BinLayout
rt.BinLayout = meta.new_type("BinLayout", function()
    local out = meta.new(rt.BinLayout, {
        _child = nil
    }, rt.Drawable, rt.Widget)
    return out
end)

--- @brief set singular child
function rt.BinLayout:set_child(child)
    meta.assert_isa(self, rt.BinLayout)
    meta.assert_isa(self, rt.Widget)
    self._child = child
    self:reformat()
end

--- @brief get singular child
function rt.BinLayout:get_child()
    meta.assert_isa(self, rt.BinLayout)
    return self._child
end

--- @overload rt.Drawable.draw
function rt.BinLayout:draw()
    meta.assert_isa(self, rt.BinLayout)
    if self:get_is_visible() then
        self._child:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.BinLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.BinLayout)
    self._child:fit_into(rt.AABB(x, y, width, height))
end

--- @overload rt.Widget.measure
function rt.BinLayout:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @brief test BinLayout
function rt.test.bin_layout()
    -- TODO
end
rt.test.bin_layout()
