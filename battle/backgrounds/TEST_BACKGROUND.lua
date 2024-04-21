--- @class bt.BattleBackground.TEST_BACKGROUND
bt.BattleBackground.TEST_BACKGROUND = meta.new_type("TEST_BACKGROUND", bt.BattleBackgroundImplementation, function()
    return meta.new(bt.BattleBackground.TEST_BACKGROUND, {
        _spline = {},
        _background_shape = {},
        _shader = {},
        _bounds = rt.AABB(0, 0, 1, 1),
        _is_realized = false,
        _elapsed = 0
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
end

--- @override
function bt.BattleBackground.TEST_BACKGROUND:draw()
    if self._is_realized then
        self._shader:bind()
        self._shape:draw()
        self._shader:unbind()
        self._spline:draw()
    end
end

--- @override
function bt.BattleBackground.TEST_BACKGROUND:step(delta, magnitudes)
    if not self._is_realized then return end

    self._elapsed = self._elapsed + delta
    local intensity = 0
    local weight = 0.7
    local x, y, w, h, n = self._bounds.x, self._bounds.y, self._bounds.width, self._bounds.height, #magnitudes
    local points = {x + w, y + h, x + w, y + h}
    for i = 1, n do
        local value = magnitudes[i]
        table.insert(points, x + w - (i - 1) / n * w)
        table.insert(points, y + h - weight * value * h)
        intensity = intensity + value
    end

    local dup_x, dup_y = points[#points - 1], points[#points]
    table.insert(points, x)
    table.insert(points, h)

    self._spline = rt.BSpline(points)
    self._shader:send("time", self._elapsed)
    self._shader:send("intensity", intensity / #magnitudes)
end

