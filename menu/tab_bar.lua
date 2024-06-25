--- @class mn.TabBar
mn.TabBar = meta.new_type("TabBar", rt.Widget, function()
    return meta.new(mn.TabBar, {
        _items = {}, -- cf. push
        _rail_width = rt.settings.frame.thickness,
    })
end)

--- @brief
function mn.TabBar:push(...)
    for widget in range(...) do
        local to_insert = {
            widget = widget,
            base_rectangle = rt.Rectangle(0, 0, 1, 1),
            base_triangle = rt.Triangle(0, 0, 1, 1, 0.5, 0.5),
            rail = rt.Line(0, 0, 1, 1),
            rail_outline = rt.Line(0, 0, 1, 1),
        }

        if self._is_realized then
            to_insert.widget:realize()
        end

        to_insert.base_rectangle:set_color(rt.Palette.BACKGROUND)
        to_insert.base_triangle:set_color(rt.Palette.BACKGROUND)

        to_insert.rail:set_color(rt.Palette.FOREGROUND)
        to_insert.rail:set_line_width(self._rail_width)
        to_insert.rail_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
        to_insert.rail_outline:set_line_width(self._rail_width + 2)

        for rail in range(to_insert.rail, to_insert.rail_outline) do
            rail:set_line_join(rt.LineJoin.BEVEL)
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
    end
end

--- @override
function mn.TabBar:size_allocate(x, y, width, height)
    local current_x, current_y = x, y
    local eps = 5
    for item in values(self._items) do
        local m = rt.settings.margin_unit

        local w, h = item.widget:measure()
        item.widget:fit_into(current_x + m, current_y + m, w, h)

        local base_w = w + 2 * m
        local base_h = h + m
        item.base_rectangle:resize(current_x, current_y, base_w, base_h)

        local triangle_w = 3 * m
        item.base_triangle:resize(
            current_x + base_w, current_y,
            current_x + base_w, current_y + base_h,
            current_x + base_w + triangle_w, current_y + base_h
        )

        for rail in range(item.rail, item.rail_outline) do
            rail:resize(
                current_x, current_y + base_h + eps,
                current_x, current_y,
                current_x + base_w, current_y,
                current_x + base_w + triangle_w + eps, current_y + base_h + eps
            )
        end

        current_x = current_y + base_w + triangle_w
    end
end

--- @override
function mn.TabBar:draw()
    for item in values(self._items) do
        item.base_rectangle:draw()
        item.base_triangle:draw()
        item.rail_outline:draw()
        item.rail:draw()
        item.widget:draw()
        item.widget:draw_bounds()
    end
end
