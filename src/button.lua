--- @class rt.Button
--- @signal clicked (::Button) -> nil
rt.Button = meta.new_type("Button", function()
    local out = meta.new(rt.Button, {
        _base = rt.Rectangle(0, 0, 1, 1),
        _outline = rt.Rectangle(0, 0, 1, 1, 10),
        _overlay_shadow = rt.Rectangle(0, 0, 1, 1),
        _focus_highlight = rt.Rectangle(0, 0, 1, 1, 10),
        _depressed = false,
        _child = {}
    }, rt.Drawable, rt.Widget)

    rt.add_signal_component(out)
    out.signal:add("clicked")

    out._base:set_color(rt.RGBA(0.5, 0.5, 0.5, 1))
    out._overlay_shadow:set_color(rt.RGBA(0, 0, 0, 0.5))
    out._outline:set_color(rt.RGBA(0, 0, 0, 1))
    out._outline:set_is_outline(true)
    out._outline:set_line_width(5)

    out._focus_highlight:set_color(rt.RGBA(0, 1, 1, 0.5))
    out._focus_highlight:set_is_outline(true)
    out._focus_highlight:set_line_width(4)

    out._overlay_shadow:set_is_visible(false)

    local mouse = rt.add_mouse_component(out)
    mouse.signal:connect("button_pressed", function(self, x, y, which_button)
        self.instance:_resolve_clicked()
    end)
    mouse.signal:connect("button_released", function(self, x, y, which_button)
        self.instance:_resolve_unclicked()
    end)

    local key = rt.add_keyboard_component(out)
    key.signal:connect("key_pressed", function(self, key)
        if self.instance._depressed then return end
        if rt.KeyMap.should_trigger("activate", key) then
            self.instance:_resolve_clicked()
        end
    end)
    key.signal:connect("key_released", function(self, key)
        if not self.instance._depressed then return end
        if rt.KeyMap.should_trigger("activate", key) then
            self.instance:_resolve_unclicked()
        end
    end)

    local gamepad = rt.add_gamepad_component(out)
    gamepad.signal:connect("button_pressed", function(self, id, button)
        if self.instance._depressed then return end
        if rt.KeyMap.should_trigger("activate", key) then
            self.instance:_resolve_clicked()
        end
    end)
    gamepad.signal:connect("button_released", function(self, id, button)
        if self.instance._depressed then return end
        if rt.KeyMap.should_trigger("activate", key) then
            self.instance:_resolve_unclicked()
        end
    end)
    return out
end)

--- @brief
function rt.Button:_resolve_clicked()
    meta.assert_isa(self, rt.Button)
    self._overlay_shadow:set_is_visible(true)
    self._depressed = true
end

--- @brief
function rt.Button:_resolve_unclicked()
    meta.assert_isa(self, rt.Button)

    if self._depressed then
        self.signal:emit("clicked")
    end

    self._overlay_shadow:set_is_visible(false)
    self._depressed = false
end

--- @brief
function rt.Button:size_allocate(x, y, width, height)
    self._base:set_position(x + 1, y + 1)
    self._base:set_size(width - 2, height - 2)

    self._outline:set_position(x, y)
    self._outline:set_size(width, height)

    self._overlay_shadow:set_position(x, y)
    self._overlay_shadow:set_size(width, height)

    self._focus_highlight:set_position(x, y)
    self._focus_highlight:set_size(width, height)

    if not meta.is_nil(self._child) then
        self._child:fit_into(rt.AABB(x + 5, y + 5, width - 10, height - 10))
    end
end

--- @brief
function rt.Button:measure()
    if meta.is_nil(self._child) then
        return 2*5 + 2*5
    else
        local w, h = self._child:measure()
        return w + 5, h + 5
    end
end

--- @brief
function rt.Button:draw()
    self._base:draw()
    self._child:draw()
    self._outline:draw()
    self._overlay_shadow:draw()

    if self:get_has_focus() then
        self._focus_highlight:draw()
    end
end

--- @brief
function rt.Button:set_child(child)
    meta.assert_isa(child, rt.Widget)
    self._child = child
    self:reformat()
end

--- @brief
function rt.Button:get_child()
    return self._child
end
