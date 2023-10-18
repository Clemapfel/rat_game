--- @class rt.OverlayLayout
rt.OverlayLayout = meta.new_type("OverlayLayout", function()
    return meta.new(rt.OverlayLayout, {
        _base_child = {},
        _overlays = rt.Queue()
    }, rt.Drawable, rt.Widget)
end)

--- @overload rt.Drawable.draw
function rt.OverlayLayout:draw()
    if not self:get_is_visible() then
        return
    end

    if meta.isa(self._base_child, rt.Widget) then
        self._base_child:draw()
    end

    for _, child in pairs(self._overlays) do
        child:draw()
    end
end

--- @overlay rt.Widget.size_allocate
function rt.OverlayLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.OverlayLayout)

    x = x + self:get_margin_left()
    y = y + self:get_margin_top()
    width = width - (self:get_margin_left() + self:get_margin_right())
    height = height - (self:get_margin_top() + self:get_margin_bottom())

    if meta.isa(self._base_child, rt.Widget) then
        self._base_child:fit_into(rt.AABB(x, y, width, height))
    end

    for _, child in pairs(self._overlays) do
        child:fit_into(rt.AABB(x, y, width, height))
    end
end

--- @brief
function rt.OverlayLayout:set_base_child(child)
    meta.assert_isa(self, rt.OverlayLayout)
    meta.assert_isa(child, rt.Widget)

    self:remove_base_child()
    child:set_parent(self)
    self._base_child = child
end

--- @brief
function rt.OverlayLayout:remove_base_child()
    meta.assert_isa(self, rt.OverlayLayout)

    if not meta.is_nil(self._base_child) then
        self._base_child:set_parent(nil)
        self._base_child = nil
    end
end

--- @brief
function rt.OverlayLayout:add_overlay(child)
    meta.assert_isa(self, rt.OverlayLayout)
    meta.assert_isa(child, rt.Widget)
    child:set_parent(self)
    self._overlays:push_back(child)
end

--- @brief test OverlayLayout
function rt.test.overlay_layout()
    -- TODO
end
rt.test.overlay_layout()