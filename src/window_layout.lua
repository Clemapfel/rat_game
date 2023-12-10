rt.WindowHandler = {}
rt.WindowHandler._components = {}
meta.make_weak(rt.WindowHandler._components, false, true)

--- @class rt.WindowLayout
--- @brief Single-child container, resized with window
rt.WindowLayout = meta.new_type("WindowLayout", function()
    local out = meta.new(rt.WindowLayout, {
        _child = {}
    }, rt.Drawable, rt.Widget)
    rt.WindowHandler._components[meta.hash(out)] = out
    return out
end)

-- @brief window resized
function love.resize(width, height)
    for _, window in pairs(rt.WindowHandler._components) do
        window:fit_into(rt.AABB(0, 0, width, height))
    end
    rt.Renderer:set_resolution(width, height)
end

--- @brief window looses focus
function love.focus(b)
    for _, window in pairs(rt.WindowHandler._components) do
        window:set_has_focus(b)
    end
end

--- @brief set singular child
--- @param child rt.Widget
function rt.WindowLayout:set_child(child)
    meta.assert_widget(child)

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
function rt.WindowLayout:get_child()

    return self._child
end

--- @brief remove child
function rt.WindowLayout:remove_child()
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @overload rt.Drawable.draw
function rt.WindowLayout:draw()
    if self:get_is_visible() and meta.is_widget(self._child) then
        self._child:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.WindowLayout:size_allocate(x, y, width, height)
    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x, y, width, height))
    end
end

--- @overload rt.Widget.measure
function rt.WindowLayout:measure()
    if not meta.is_widget(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.WindowLayout:realize()
    if self:get_is_realized() then return end

    self._realized = true
    if meta.is_widget(self._child) then
        self._child:realize()
    end
end

--- @brief test WindowLayout
function rt.test.bin_layout()
    error("TODO")
end

