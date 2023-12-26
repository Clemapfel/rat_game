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
    for x_i = 0, n_steps + 1 do
        local to_insert = {}
        for y_i = 0, n_steps + 1 do
            if x_i % 2 == 1 then
                table.insert(to_insert, {x_i * x_step , y_i * y_step + 0.5 * y_step })
            else
                table.insert(to_insert, {x_i * x_step , y_i * y_step})
            end
        end
        table.insert(vertices, to_insert)
    end
    for row_i = 1, n_steps + 1, 2 do
        for col_i = 1, n_steps + 1, 1 do
            local x, y = table.unpack(vertices[row_i][col_i])
            vertices[row_i][col_i][1] = x + rt.random.integer(-16, 16)
            vertices[row_i][col_i][2] = y + rt.random.integer(-16, 16)
        end
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
end

--- @overload
function bt.BattleTransition:draw()
    love.graphics.scale(0.9)
    for _, shape in pairs(self._triangles) do
        shape:draw()
    end
end