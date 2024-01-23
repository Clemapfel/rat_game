--- @class rt.OverlayLayout
rt.OverlayLayout = meta.new_type("OverlayLayout", function()
    return meta.new(rt.OverlayLayout, {
        _base_child = {},
        _overlays = rt.List()
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
    x = x + self:get_margin_left()
    y = y + self:get_margin_top()
    width = clamp(width - (self:get_margin_left() + self:get_margin_right()), 0)
    height = clamp(height - (self:get_margin_top() + self:get_margin_bottom()), 0)

    if meta.isa(self._base_child, rt.Widget) then
        self._base_child:fit_into(rt.AABB(x, y, width, height))
    end

    for _, child in pairs(self._overlays) do
        child:fit_into(rt.AABB(x, y, width, height))
    end
end

--- @overload rt.Widget.realize
function rt.OverlayLayout:realize()

    self._realized = true

    if meta.is_widget(self._base_child) then
        self._base_child:realize()
    end

    local i = 1
    for _, child in pairs(self._overlays) do
        child:realize()
        i = i + 1
    end
end

--- @overload rt.Widget.measure
function rt.OverlayLayout:measure()

    local max_w = 0
    local max_h = 0

    if meta.is_widget(self._base_child) then
        max_w, max_h = self._base_child:measure()
    end

    for _, child in pairs(self._overlays) do
        local w, h = child:measure()
        max_w = math.max(max_w, w)
        max_h = math.max(max_h, h)
    end

    return max_w, max_h
end

--- @brief set lower-most child
--- @param child rt.Widget
function rt.OverlayLayout:set_base_child(child)

    self:remove_base_child()
    child:set_parent(self)
    self._base_child = child

    if self:get_is_realized() then child:realize() end
end

--- @brief remove lower most child
function rt.OverlayLayout:remove_base_child()

    if meta.is_widget(self._base_child) then
        self._base_child:set_parent(nil)
        self._base_child = nil
    end
end

--- @brief add overlay child on top
--- @param child rt.Widget
function rt.OverlayLayout:push_overlay(child)

    child:set_parent(self)
    self._overlays:push_back(child)
    if self:get_is_realized() then child:realize() end
end

--- @brief remove top-most overlay
function rt.OverlayLayout:pop_overlay()

    local child = self._overlays:pop_back()
    child:set_parent(nil)
    return child
end

--- @brief test OverlayLayout
function rt.test.overlay_layout()
    error("TODO")
end
