rt.settings.battle.background.triangle_tiling = {
    shader_path = "battle/backgrounds/triangle_tiling.glsl",
    scroll_speed = 20
}

bt.Background.TRIANGLE_TILING = meta.new_type("TRIANGLE_TILING", bt.Background, function()
    return meta.new(bt.Background.TRIANGLE_TILING, {
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _triangles = {}, -- Table<rt.Shape>
        _elapsed = 0
    })
end)

--- @override
function bt.Background.TRIANGLE_TILING:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._shader = rt.Shader(rt.settings.battle.background.triangle_tiling.shader_path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.Background.TRIANGLE_TILING:size_allocate(x, y, width, height)
    local n_steps = 10

    local x_step = width / n_steps --math.max(width / n_steps, height / n_steps)
    local y_step = height / n_steps --math.max(width / n_steps, height / n_steps)

    local vertices = {}
    for x_i = 0, n_steps + 2 do
        local to_insert = {}
        for y_i = 0, n_steps + 2 do
            if x_i % 2 == 1 then
                table.insert(to_insert, {x_i * x_step , y_i * y_step + 0.5 * y_step})
            else
                table.insert(to_insert, {x_i * x_step , y_i * y_step})
            end
        end
        table.insert(vertices, to_insert)
    end

    self._triangles = {}
    for row_i = 1, n_steps + 1, 1 do
        for col_i = 1, n_steps + 1, 1 do

            if row_i % 2 == 1 then
                local a = vertices[row_i][col_i]
                local b = vertices[row_i + 1][col_i]
                local c = vertices[row_i][col_i + 1]
                table.insert(self._triangles, rt.Triangle(
                    a[1], a[2],
                    b[1], b[2],
                    c[1], c[2]
                ))

                a = vertices[row_i + 1][col_i]
                b = vertices[row_i + 1][col_i + 1]
                c = vertices[row_i][col_i + 1]
                table.insert(self._triangles, rt.Triangle(
                    a[1], a[2],
                    b[1], b[2],
                    c[1], c[2]
                ))
            else
                local a = vertices[row_i+1][col_i]
                local b = vertices[row_i][col_i]
                local c = vertices[row_i+1][col_i+1]
                table.insert(self._triangles, rt.Triangle(
                    a[1], a[2],
                    b[1], b[2],
                    c[1], c[2]
                ))
            end
        end
    end

    for _, shape in pairs(self._triangles) do
        shape:set_is_outline(true)
        shape:set_line_width(3)
    end

    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.TRIANGLE_TILING:update(delta)
    self._elapsed = self._elapsed + delta
    self._shader:send("elapsed", self._elapsed)
end

--- @override
function bt.Background.TRIANGLE_TILING:draw()
    self._shader:bind()

    for _, shape in pairs(self._triangles) do
        shape:draw()
    end

    self._shader:unbind()
end
