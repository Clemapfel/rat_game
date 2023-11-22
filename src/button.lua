--- @class rt.Button
--- @signal clicked (::Button) -> nil
rt.Button = meta.new_type("Button", function(child)
    local out = meta.new(rt.Button, {
        _base = rt.Rectangle(0, 0, 1, 1),
        _outline = rt.Rectangle(0, 0, 1, 1, 10),
        _overlay_shadow = rt.Rectangle(0, 0, 1, 1),
        _depressed = false,
        _child = {},
        _input = {}
    }, rt.Drawable, rt.Widget, rt.SignalEmitter)

    out:signal_add("clicked")

    out._base:set_color(rt.Palette.BASE)
    out._outline:set_color(rt.Palette.BASE_OUTLINE)
    out._outline:set_is_outline(true)
    out._outline:set_line_width(5)

    out._overlay_shadow:set_color(rt.RGBA(0, 0, 0, 0.5))
    out._overlay_shadow:set_is_visible(false)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", function(_, button, self)
        if button == rt.InputButton.A and self._depressed == false then
            self._overlay_shadow:set_is_visible(true)
            self._depressed = true
            self:signal_emit("clicked")
        end
    end, out)

    out._input:signal_connect("released", function(_, button, self)
        if button == rt.InputButton.A and self._depressed == true then
            self._overlay_shadow:set_is_visible(false)
            self._depressed = false
        end
    end, out)

    if not meta.is_nil(child) then
        meta.assert_isa(child, rt.Widget)
        out:set_child(child)
    end

    return out
end)

--- @overload rt.Drawable.draw
function rt.Button:draw()
    meta.assert_isa(self, rt.Button)
    if self:get_is_visible() == false then return end

    self._base:draw()
    self._outline:draw()

    if meta.is_widget(self._child) then
        self._child:draw()
    end

    self._overlay_shadow:draw()
end

--- @overload rt.Widget.size_allocate
function rt.Button:size_allocate(x, y, width, height)
    self._base:set_position(x + 1, y + 1)
    self._base:set_size(width - 2, height - 2)

    self._outline:set_position(x, y)
    self._outline:set_size(width, height)

    self._overlay_shadow:set_position(x, y)
    self._overlay_shadow:set_size(width, height)

    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x + 5, y + 5, width - 10, height - 10))
    end
end

--- @brief set singular child
--- @param child rt.Widget
function rt.Button:set_child(child)
    meta.assert_isa(self, rt.Button)
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

--- @overload rt.Widget.realize
function rt.Button:realize()
    meta.assert_isa(self, rt.Button)

    if meta.is_widget(self._child) then
        self._child:realize()
    end
    rt.Widget.realize(self)
end

--- @brief get singular child
--- @return rt.Widget
function rt.Button:get_child()
    meta.assert_isa(self, rt.Button)
    return self._child
end

--- @brief remove child
function rt.Button:remove_child()
    meta.assert_isa(self, rt.Button)
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

