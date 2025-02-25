--- @class bt.BattleBackground.TEST_BACKGROUND
bt.BattleBackground.TEST_BACKGROUND = meta.new_type("TEST_BACKGROUND", bt.BattleBackgroundImplementation, function()
    return meta.new(bt.BattleBackground.TEST_BACKGROUND, {
        _spline = {},
        _background_shape = {},
        _shader = {},
        _bounds = rt.AABB(0, 0, 1, 1),
        _is_realized = false,
        _elapsed = 0,
        _line_elapsed = 0,
        _line_duration = 4 / 60,

        _lines_a = {},
        _lines_b = {},
    })
end)

--- @override
function bt.BattleBackground.TEST_BACKGROUND:realize()
    if self._is_realized == true then return end

    self._shader = rt.Shader("assets/shaders/battle_test_background.glsl")
    self._shape = rt.VertexRectangle(self._bounds.x, self._bounds.y, self._bounds.height, self._bounds.width)
    self._spline = rt.Spline({
        self._bounds.x,
        self._bounds.y + self._bounds.height,
        self._bounds.x + self._bounds.width,
        self._bounds.y + self._bounds.height
    })

    self._is_realized = true
end

--- @override
function bt.BattleBackground.TEST_BACKGROUND:resize(x, y, width, height)
    self._bounds = rt.AABB(x, y, width, height)
    if self._is_realized then
        local x, y, w, h = self._bounds.x, self._bounds.y, self._bounds.width, self._bounds.height
        self._shape:set_vertex_position(1, x, y)
        self._shape:set_vertex_position(2, x + w, y)
        self._shape:set_vertex_position(3, x + w, y + h)
        self._shape:set_vertex_position(4, x, y + h)

        self._spline = rt.BSpline({
            self._bounds.x,
            self._bounds.y + self._bounds.height,
            self._bounds.x + self._bounds.width,
            self._bounds.y + self._bounds.height
        })
    end
    local n_tiles = 15
    self._lines_a = {}
    self._lines_b = {}
    local line_color = rt.Palette.NEON_RED_4
    local line_width = 2
    width = width - line_width
    x = x + 0.5 * line_width
    y = y + 0.5 * line_width
    for x_offset = 0, width, width / n_tiles do
        for y_offset = 0, height, width / n_tiles do -- sic

            local a = rt.Line(x + x_offset, y, x + x_offset, y + height)
            a:set_color(line_color)
            a:set_line_width(line_width)
            table.insert(self._lines_a, a)

            local b = rt.Line(x, y + y_offset, x + width, y + y_offset)
            b:set_color(line_color)
            b:set_line_width(line_width)
            table.insert(self._lines_b, b)
        end
    end
end

--- @override
function bt.BattleBackground.TEST_BACKGROUND:draw()
    if self._is_realized then
        self._shader:bind()
        self._shape:draw()
        self._shader:unbind()

        rt.graphics.set_color(rt.Palette.NEON_RED_3)
        love.graphics.setLineJoin("miter")
        love.graphics.setLineWidth(5)
        self._spline:draw()

        for line in values(self._lines_a) do
            line:draw(self._lines_a)
        end

        for line in values(self._lines_b) do
            line:draw(self._lines_a)
        end
    end
end

--- @override
function bt.BattleBackground.TEST_BACKGROUND:step(delta, magnitudes)
    if not self._is_realized then return end

    self._elapsed = self._elapsed + delta
    local low_intensity = 0
    local high_intensity = 0
    local weight = 1
    local x, y, w, h, n = self._bounds.x, self._bounds.y, self._bounds.width, self._bounds.height, #magnitudes
    local points = {x + w, y + h, x + w, y + h}
    for i = 1, n do
        local value = magnitudes[i]
        table.insert(points, x + w - (i - 1) / n * w)
        table.insert(points, y + h - weight * value * h)
        if i < n / 2 then
            low_intensity = low_intensity + value
        elseif i > 0.8 * n then
            high_intensity = high_intensity + value
        end
    end

    local dup_x, dup_y = points[#points - 1], points[#points]
    table.insert(points, x)
    table.insert(points, h)

    self._line_elapsed = self._line_elapsed + delta
    if self._line_elapsed > self._line_duration then
        self._spline = rt.BSpline(points)
        self._line_elapsed = 0
    end

    if _low_sum == nil then _low_sum = 0 end
    _low_sum = _low_sum + low_intensity / #magnitudes
    --self._shader:send("time", self._elapsed)
    self._shader:send("low_intensity", _low_sum)
    self._shader:send("high_intensity", high_intensity / #magnitudes)
end

