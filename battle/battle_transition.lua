--- @class bt.BattleTransition
bt.BattleTransition = meta.new_type("BattleTransition", function()
    local out = meta.new(bt.BattleTransition, {
        _triangles = {} -- Table<rt.Shape>
    }, rt.Widget, rt.Drawable, rt.Animation)
    return out
end)

--- @overload
function bt.BattleTransition:size_allocate(x, y, width, height)

    local n_steps = 10
    local x_step = width / n_steps
    local y_step = height / n_steps

    local vertices = {}
    local step = 1
    local half_step = 1 / 6
    local h = math.sin(math.pi / 3)

    local vertices = rt.Matrix(n_steps + 2, n_steps + 2)
    for x_i = 0, n_steps, 1 do
        for y_i = 0, n_steps, 1 do
            local x_pos, y_pos
            if x_i % 2 == 0 then
                x_pos = x_i
                y_pos = y_i + 0.5
            else
                x_pos = x_i
                y_pos = y_i
            end
            vertices:set(x_i + 1, y_i + 1, {x_pos, y_pos})
        end
    end

    local pixel_size_x = 1 / width
    local pixel_size_y = 1 / height
    local offset = -0.5
    for _, v in ipairs(vertices) do
        --v[1] = v[1] + rt.random.number(-offset, offset)
        --v[2] = v[2] + rt.random.number(-offset, offset)
    end

    local x_scale = width / n_steps
    local y_scale = height / n_steps
    
    self._triangles = {}

    -- upper most row
    for x_i = 1, n_steps + 1 - 1, 1 do

        local a = vertices:get(x_i, 1)
        local b = vertices:get(x_i + 1, 1)
        local c = {a[1], 0}

        table.insert(self._triangles, rt.Polygon(
                a[1] * x_scale, a[2] * y_scale,
                b[1] * x_scale, b[2] * y_scale,
                c[1] * x_scale, c[2] * y_scale
        ))

        a = vertices:get(x_i + 1, 1)
        b = vertices:get(x_i, 1)
        c = {a[1], 0}

        table.insert(self._triangles, rt.Polygon(
                a[1] * x_scale, a[2] * y_scale,
                b[1] * x_scale, b[2] * y_scale,
                c[1] * x_scale, c[2] * y_scale
        ))
    end

    -- tiling
    for y_i = 1, n_steps + 1 - 1 , 1 do
        for x_i = 1, n_steps + 1 - 1, 1 do

            local a, b, c
            local color
            if x_i % 2 == 0 then
                a = vertices:get(x_i, y_i)
                b = vertices:get(x_i + 1, y_i)
                c = vertices:get(x_i, y_i + 1)

                table.insert(self._triangles, rt.Polygon(
                        a[1] * x_scale, a[2] * y_scale,
                        b[1] * x_scale, b[2] * y_scale,
                        c[1] * x_scale, c[2] * y_scale
                ))

                a = vertices:get(x_i + 1, y_i)
                b = vertices:get(x_i + 1, y_i + 1)
                c = vertices:get(x_i, y_i + 1)

                table.insert(self._triangles, rt.Polygon(
                        a[1] * x_scale, a[2] * y_scale,
                        b[1] * x_scale, b[2] * y_scale,
                        c[1] * x_scale, c[2] * y_scale
                ))

            else
                a = vertices:get(x_i, y_i)
                b = vertices:get(x_i + 1, y_i)
                c = vertices:get(x_i + 1, y_i + 1)

                table.insert(self._triangles, rt.Polygon(
                        a[1] * x_scale, a[2] * y_scale,
                        b[1] * x_scale, b[2] * y_scale,
                        c[1] * x_scale, c[2] * y_scale
                ))

                a = vertices:get(x_i, y_i)
                b = vertices:get(x_i + 1, y_i + 1)
                c = vertices:get(x_i, y_i + 1)

                table.insert(self._triangles, rt.Polygon(
                        a[1] * x_scale, a[2] * y_scale,
                        b[1] * x_scale, b[2] * y_scale,
                        c[1] * x_scale, c[2] * y_scale
                ))
            end
        end
    end

    -- lower most row
    for x_i = 1, n_steps + 1 - 1, 1 do

        local y_index = n_steps + 1

        if x_i % 2 == 1 then

            local a = vertices:get(x_i, y_index)
            local b = vertices:get(x_i + 1, y_index)
            local c = {b[1], a[2]}

            table.insert(self._triangles, rt.Polygon(
                    a[1] * x_scale, a[2] * y_scale,
                    b[1] * x_scale, b[2] * y_scale,
                    c[1] * x_scale, c[2] * y_scale
            ))
        else
            local a = vertices:get(x_i, y_index)
            local b = vertices:get(x_i + 1, y_index)
            local c = {a[1], b[2]}

            table.insert(self._triangles, rt.Polygon(
                a[1] * x_scale, a[2] * y_scale,
                b[1] * x_scale, b[2] * y_scale,
                c[1] * x_scale, c[2] * y_scale
            ))
        end
    end

    local i = 0
    for _, shape in pairs(self._triangles) do
        shape:set_is_outline(false)
        shape:set_line_width(3)
        shape:set_color(rt.HSVA(i / #self._triangles), 1, 1, 1)
        i = i + 1
    end
end

--- @overload
function bt.BattleTransition:draw()
    for _, shape in pairs(self._triangles) do
        shape:draw()
    end
end