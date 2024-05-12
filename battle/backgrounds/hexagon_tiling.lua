rt.settings.battle.background.hexagon_tiling = {
    shader_path = "battle/backgrounds/hexagon_tiling.glsl",
    scroll_speed = 20
}

bt.Background.HEXAGON_TILING = meta.new_type("HEXAGON_TILING", bt.Background, function()
    return meta.new(bt.Background.HEXAGON_TILING, {
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _triangles = {}, -- Table<rt.Shape>
        _elapsed = 0
    })
end)

--- @override
function bt.Background.HEXAGON_TILING:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._shader = rt.Shader(rt.settings.battle.background.hexagon_tiling.shader_path)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
end

--- @override
function bt.Background.HEXAGON_TILING:size_allocate(x, y, width, height)
    local n_steps = width / 100
    local x_step = width / n_steps
    local y_step = height / n_steps

    local vertices = {}
    local step = 1
    local half_step = 1 / 6
    local h = math.sin(math.pi / 3)

    local vertices = {}
    for x_i = -1, n_steps, 3 do
        for y_i = -1, math.floor(n_steps / h) + 1 do
            -- source: https://alexwlchan.net/2016/tiling-the-plane-with-pillow/
            local x_pos
            if y_i % 2 == 0 then
                x_pos = x_i
            else
                x_pos = x_i + 1.5
            end

            local x, y = 0, -0.5

            for _, v in pairs({
                {x + x_pos,        y + y_i * h},
                {x + x_pos + 1,    y + y_i * h},
                {x + x_pos + 1.5,  y + (y_i + 1) * h},
                {x + x_pos + 1,    y + (y_i + 2) * h},
                {x + x_pos,        y + (y_i + 2) * h},
                {x + x_pos - 0.5,  y + (y_i + 1) * h},
            }) do
                table.insert(vertices, v)
            end
        end
    end

    self._triangles = {}
    for i = 1, #vertices, 6 do
        local v = vertices
        local w = math.max(width / n_steps, height / n_steps)
        local h = w
        table.insert(self._triangles, rt.Polygon(
                v[i+0][1] * w, v[i+0][2] * h,
                v[i+1][1] * w, v[i+1][2] * h,
                v[i+2][1] * w, v[i+2][2] * h,
                v[i+3][1] * w, v[i+3][2] * h,
                v[i+4][1] * w, v[i+4][2] * h,
                v[i+5][1] * w, v[i+5][2] * h
        ))
    end

    for _, shape in pairs(self._triangles) do
        shape:set_is_outline(true)
        shape:set_color(rt.Palette.RED)
        shape:set_line_width(5)
    end

    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.HEXAGON_TILING:update(delta)
    self._elapsed = self._elapsed + delta
    --self._shader:send("elapsed", self._elapsed)
end

--- @override
function bt.Background.HEXAGON_TILING:draw()
    --self._shader:bind()
    --self._shape:draw()
    --self._shader:unbind()

    local scroll = rt.settings.battle.background.hexagon_tiling.scroll_speed
    rt.graphics.push()
    --rt.graphics.translate(-scroll * self._elapsed, -scroll * self._elapsed)
    for _, shape in pairs(self._triangles) do
        shape:draw()
    end
    rt.graphics.pop()
end
