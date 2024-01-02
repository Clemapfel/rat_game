rt.settings.order_queue = {
    portrait_spacing = -4 * 0.5 * rt.settings.margin_unit,
    outline_width = 3
}

--- @class bt.OrderQueue
bt.OrderQueue = meta.new_type("OrderQueue", function()
    local out = meta.new(bt.OrderQueue, {
        _current_state = {},    -- rt.Queue<bt.Entity>
        _next_state = {},       -- rt.Queue<bt.Entity>
        _arrow_body = rt.Rectangle(0, 0, 1, 1),
        _arrow_body_outline = rt.LineStrip(0, 0, 1, 1),
        _arrow_body_outline_outline = rt.LineStrip(0, 0, 1, 1),
        _arrow_head = rt.Polygon(0, 0, 0, 0, 0, 0),
        _arrow_head_outline = rt.LineStrip(0, 0, 1, 1),
        _arrow_head_outline_outline = rt.LineStrip(0, 0, 1, 1),
        _arrow_bottom = rt.Circle(0, 0, 1),
        _arrow_bottom_outline = rt.Circle(0, 0, 1),
        _arrow_bottom_outline_outline = rt.Circle(0, 0, 1),
        _turn_separator_body = rt.Rectangle(0, 0, 1, 1),
        _turn_separator_outline = rt.Rectangle(0, 0, 1, 1),
        _turn_separator_outline_outline = rt.Rectangle(0, 0, 1, 1),
        _portraits = {}         -- Table<entity.id, bt.EntityPortrait>
    }, rt.Widget, rt.Drawable, rt.Animation)

    for _, base in pairs({
        out._arrow_head,
        out._arrow_body,
        out._arrow_bottom
    }) do
        base:set_color(rt.Palette.GREY_5)
    end

    for _, outline in pairs({
        out._arrow_head_outline,
        out._arrow_body_outline,
        out._arrow_bottom_outline
    }) do
        outline:set_color(rt.Palette.GREY_1)
        outline:set_line_width(rt.settings.order_queue.outline_width)
        outline:set_is_outline(true)
    end

    for _, outline in pairs({
        out._arrow_head_outline_outline,
        out._arrow_body_outline_outline,
        out._arrow_bottom_outline_outline
    }) do
        outline:set_color(rt.Palette.BLACK)
        outline:set_line_width(rt.settings.order_queue.outline_width + 4)
        outline:set_is_outline(true)
    end

    out._arrow_body_outline:set_is_outline(true)
    return out
end)

--- @overload
function bt.OrderQueue:draw()
    if not self:get_is_visible() then return end

    self._arrow_bottom:draw()
    self._arrow_bottom_outline_outline:draw()
    self._arrow_bottom_outline:draw()
    self._arrow_body:draw()
    self._arrow_body_outline_outline:draw()
    self._arrow_body_outline:draw()
    self._arrow_head:draw()
    self._arrow_head_outline_outline:draw()
    self._arrow_head_outline:draw()

    for _, entity in pairs(self._current_state) do
        self._portraits[entity.id]:draw()
    end
end

--- @brief
function bt.OrderQueue:set_state(state)
    self._current_state = state

    for _, entity in pairs(self._current_state) do
        local id = entity.id
        if meta.is_nil(self._portraits[id]) then
            self._portraits[id] = bt.EntityPortrait(entity)
            if self:get_is_realized() then
                self._portraits[id]:realize()
            end
        end
    end

    self:reformat()
end

--- @overload
function bt.OrderQueue:realize()
    for _, portrait in pairs(self._portraits) do
        portrait:realize()
    end
    rt.Widget.realize(self)
end

--- @overload
function bt.OrderQueue:size_allocate(x, y, width, height)

    local m = 48
    local arrow_m = 0.8 * m

    local translate = function(a, b, angle, distance)
        return math3d.vec2(
            a + math.sin(rt.degrees(angle):as_radians()) * distance,
            b + -1 * math.cos(rt.degrees(angle):as_radians()) * distance
        )
    end

    x = x + width - 2 * m
    y = y + m
    width = m

    local arrow_center = math3d.vec2(x + 0.5 * width, y + 0.5 * m)
    local arrow_top = math3d.vec2(arrow_center.x, arrow_center.y - arrow_m)
    local arrow_bottom_right = math3d.vec2(translate(arrow_center.x, arrow_center.y, 1/3 * 360, arrow_m))
    local arrow_bottom_left = math3d.vec2(translate(arrow_center.x, arrow_center.y, 2/3 * 360, arrow_m))
    local arrow_base =  math3d.vec2(arrow_center.x, arrow_center.y + 0.25 * arrow_m)

    self._arrow_head:resize(
            arrow_top.x, arrow_top.y,
            arrow_bottom_right.x, arrow_bottom_right.y,
            arrow_base.x, arrow_base.y,
            arrow_bottom_left.x, arrow_bottom_left.y
    )

    for _, outline in pairs({self._arrow_head_outline, self._arrow_head_outline_outline}) do
        outline:resize(
                arrow_top.x, arrow_top.y,
                arrow_bottom_right.x, arrow_bottom_right.y,
                arrow_base.x, arrow_base.y,
                arrow_bottom_left.x, arrow_bottom_right.y,
                arrow_top.x, arrow_top.y
        )
    end

    local body_width, body_height = 0.5 * m, height - 2.5 * m
    local body_top_left = math3d.vec2(arrow_center.x - 0.5 * body_width, arrow_center.y)
    self._arrow_body:resize(
            body_top_left.x, body_top_left.y,
            body_width, body_height
    )

    for _, outline in pairs({self._arrow_body_outline, self._arrow_body_outline_outline}) do
        outline:resize(
                body_top_left.x, body_top_left.y + body_height,
                body_top_left.x, body_top_left.y,
                body_top_left.x + body_width, body_top_left.y,
                body_top_left.x + body_width, body_top_left.y + body_height
        )
    end

    for _, bottom in pairs({self._arrow_bottom, self._arrow_bottom_outline, self._arrow_bottom_outline_outline}) do
        bottom:resize(
                body_top_left.x + 0.5 * body_width, body_top_left.y + body_height,
                0.5 * body_width
        )
    end

    local portrait_w, portrait_h = 1.25 * m, 1.25 * m
    local portrait_x = body_top_left.x + 0.5 * body_width - 0.5 * portrait_w
    local portrait_y = arrow_bottom_left.y + 0.5 * rt.settings.margin_unit
    for _, entity in pairs(self._current_state) do
        local id = entity.id
        local portrait = self._portraits[id]
        portrait:set_minimum_size(portrait_w, portrait_h)
        local w, h = portrait:measure()
        portrait:fit_into(portrait_x, portrait_y, w, h)
        portrait_y = portrait_y + h + rt.settings.order_queue.portrait_spacing
    end
end