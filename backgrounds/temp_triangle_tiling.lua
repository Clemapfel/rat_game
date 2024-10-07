rt.Background.TEMP_TRIANGLE_TILING = meta.new_type("TEMP_TRIANGLE_TILING", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.TEMP_TRIANGLE_TILING, {
        _elapsed = 0,
        _triangles = {}, -- Table<Table<Number, 6>>>
        _vertices = {},  -- Table<Number>
        _n_steps = 15
    })
end)

--- @override
function rt.Background.TEMP_TRIANGLE_TILING:realize()
    if self._is_realized == true then return end
    self._is_realized = true
end

--- @override
function rt.Background.TEMP_TRIANGLE_TILING:size_allocate(x, y, width, height)

    local n_steps = self._n_steps
    local x_step = math.max(width / n_steps, height / n_steps)
    local y_step = math.max(width / n_steps, height / n_steps)

    self._vertices = {}
    local vertices = self._vertices
    for y_i = 0, n_steps + 2 do
        local to_insert = {}
        for x_i = 0, n_steps + 2 do
            if x_i % 2 == 1 then
                table.insert(to_insert, {x_i * x_step , y_i * y_step + 0.5 * y_step})
            else
                table.insert(to_insert, {x_i * x_step , y_i * y_step})
            end
        end
        table.insert(vertices, to_insert)
    end

    self._triangles = {}

end

--- @override
function rt.Background.TEMP_TRIANGLE_TILING:update(delta)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta
end

--- @override
function rt.Background.TEMP_TRIANGLE_TILING:draw()
    if self._is_realized ~= true then return end

    love.graphics.setPointSize(5)
    local hue, hue_step = 0, 1 / sizeof(self._triangles)
    for triangle in values(self._triangles) do
        love.graphics.setColor(rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(hue, 1, 0.5, 1))))
        hue = hue + hue_step
        love.graphics.polygon("fill", table.unpack(triangle))
    end

    love.graphics.setPointSize(5)

    hue_step = math.pi / 4
    for i, row in ipairs(self._vertices) do
        for point in values(row) do
            love.graphics.setColor(rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(hue, 1, 1, 1))))
            love.graphics.points(table.unpack(point))
        end
        hue = (hue + hue_step) % 1
    end
end
