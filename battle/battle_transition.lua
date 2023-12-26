--- @class bt.BattleTransition
bt.BattleTransition = meta.new_type("BattleTransition", function()
    local out = meta.new(bt.BattleTransition, {
        _triangles = {} -- Table<rt.Shape>
    }, rt.Widget, rt.Drawable, rt.Animation)
    return out
end)

--- @overload
function bt.BattleTransition:size_allocate(x, y, width, height)
    local n_steps = 15
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

            for _, v in pairs({
                {x_pos,        y_i * h},
                {x_pos + 1,    y_i * h},
                {x_pos + 1.5, (y_i + 1) * h},
                {x_pos + 1,   (y_i + 2) * h},
                {x_pos,       (y_i + 2) * h},
                {x_pos - 0.5, (y_i + 1) * h},
            }) do
                table.insert(vertices, v)
            end
        end
    end

    local pixel_size_x = 1 / width
    local pixel_size_y = 1 / height
    local offset = -0.5
    for _, v in ipairs(vertices) do
        v[1] = v[1] + rt.random.number(-offset, offset)
        v[2] = v[2] + rt.random.number(-offset, offset)
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
        shape:set_line_width(3)
    end
end

--- @overload
function bt.BattleTransition:draw()
    for _, shape in pairs(self._triangles) do
        shape:draw()
    end
end