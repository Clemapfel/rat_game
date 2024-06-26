--- @class mn.TabBar
mn.TabBar = meta.new_type("TabBar", rt.Widget, function()
    return meta.new(mn.TabBar, {
        _items = {}, -- cf. push
        _stencil = rt.Rectangle(0, 0, 1, 1),
        _rail_width = rt.settings.frame.thickness,
        _final_w = 1,
        _final_h = 1
    })
end)

--- @brief
function mn.TabBar:push(...)
    for widget in range(...) do
        local to_insert = {
            widget = widget,
            frame = rt.Frame()
        }

        if self._is_realized then
            to_insert.widget:realize()
            to_insert.frame:realize()
        end

        table.insert(self._items, to_insert)
    end
end

--- @override
function mn.TabBar:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for item in values(self._items) do
        item.widget:realize()
        item.frame:realize()
    end
end

--- @override
function mn.TabBar:size_allocate(x, y, width, height)
    local current_x, current_y = x + rt.settings.frame.thickness, y
    local max_h = NEGATIVE_INFINITY
    local eps = 20
    local m = rt.settings.margin_unit

    for item in values(self._items) do
        local w, h = item.widget:measure()
        item.widget:fit_into(current_x + m, current_y + m, w, h)

        local base_w = w + 2 * m
        local base_h = h + 2 * m + eps
        item.frame:fit_into(current_x, current_y, base_w, base_h)

        current_x = current_x + base_w + 2 * rt.settings.frame.thickness
        max_h = math.max(max_h, base_h)
    end

    self._final_w, self._final_h = current_x - x, max_h - 2 * m
    self._stencil:resize(x - eps, y + max_h - eps, current_x - x + 2 * eps, 1.5 * eps)
end

--- @override
function mn.TabBar:draw()
    for item in values(self._items) do

        local stencil_value = meta.hash(self._stencil) % 255
        rt.graphics.stencil(stencil_value, self._stencil)
        rt.graphics.set_stencil_test(rt.StencilCompareMode.NOT_EQUAL, stencil_value)
        item.frame:draw()
        item.widget:draw()
        rt.graphics.set_stencil_test()
    end
end

--- @override
function mn.TabBar:measure()
    return self._final_w, self._final_h
end