--- @class bt.OrderQueue
bt.OrderQueue = meta.new_type("OrderQueue", function()
    local out = meta.new(bt.OrderQueue, {
        _current_state = {},    -- Table<Number, bt.Entity>
        _next_state = {},       -- Table<Number, bt.Entity>
        _arrow_body = rt.Rectangle(0, 0, 1, 1),
        _arrow_body_outline = rt.LineStrip(0, 0, 1, 1),
        _arrow_head = rt.Polygon(0, 0, 0, 0, 0, 0),
        _arrow_head_outline = rt.LineStrip(0, 0, 1, 1),
        _arrow_bottom = rt.Circle(0, 0, 1),
        _arrow_bottom_outline = rt.Circle(0, 0, 1)
    }, rt.Widget, rt.Drawable, rt.Animation)

    for _, base in pairs({
        out._arrow_head,
        out._arrow_body,
        out._arrow_bottom
    }) do
        base:set_color(rt.Palette.BASE)
    end

    for _, outline in pairs({
        out._arrow_head_outline,
        out._arrow_body_outline,
        out._arrow_bottom_outline
    }) do
        outline:set_color(rt.Palette.BASE_OUTLINE)
        outline:set_line_width(1)
        outline:set_is_outline(true)
    end

    out._arrow_body_outline:set_is_outline(true)
    return out
end)

--- @overload
function bt.OrderQueue:draw()
    if not self:get_is_visible() then return end

    self._arrow_bottom:draw()
    self._arrow_bottom_outline:draw()
    self._arrow_body:draw()
    self._arrow_body_outline:draw()
    self._arrow_head:draw()
    self._arrow_head_outline:draw()
end

--- @overload
function bt.OrderQueue:size_allocate(x, y, width, height)

    local m = 32
    x = x + width - 2 * m
    y = y + m
    width = m

    local arrow_center = math3d.vec2(x + 0.5 * width, y + 0.5 * m)

    local translate = function(a, b, angle, distance)
       return math3d.vec2(
            a + math.sin(rt.degrees(angle):as_radians()) * distance,
            b + -1 * math.cos(rt.degrees(angle):as_radians()) * distance
       )
    end
    local arrow_top = math3d.vec2(arrow_center.x, arrow_center.y - m)
    local arrow_bottom_right = math3d.vec2(translate(arrow_center.x, arrow_center.y, 1/3 * 360, m))
    local arrow_bottom_left = math3d.vec2(translate(arrow_center.x, arrow_center.y, 2/3 * 360, m))
    local arrow_base =  math3d.vec2(arrow_center.x, arrow_center.y + 0.25 * m)

    self._arrow_head:resize(
        arrow_top.x, arrow_top.y,
        arrow_bottom_right.x, arrow_bottom_right.y,
        arrow_base.x, arrow_base.y,
        arrow_bottom_left.x, arrow_bottom_left.y
    )

    self._arrow_head_outline:resize(
        arrow_top.x, arrow_top.y,
        arrow_bottom_right.x, arrow_bottom_right.y,
        arrow_base.x, arrow_base.y,
        arrow_bottom_left.x, arrow_bottom_right.y,
        arrow_top.x, arrow_top.y
    )

    local body_width, body_height = 0.5 * m, height - 2.5 * m
    local body_top_left = math3d.vec2(arrow_center.x - 0.5 * body_width, arrow_center.y)
    self._arrow_body:resize(
        body_top_left.x, body_top_left.y,
        body_width, body_height
    )

    self._arrow_body_outline:resize(
        body_top_left.x, body_top_left.y + body_height,
        body_top_left.x, body_top_left.y,
        body_top_left.x + body_width, body_top_left.y,
        body_top_left.x + body_width, body_top_left.y + body_height
    )

    for _, bottom in pairs({self._arrow_bottom, self._arrow_bottom_outline}) do
        bottom:resize(
            body_top_left.x + 0.5 * body_width, body_top_left.y + body_height,
            0.5 * body_width
        )
    end
end