--- @class bt.BattleTransition
bt.BattleTransition = meta.new_type("BattleTransition", rt.Widget, rt.Animation, function(n_tiles)
    local out = meta.new(bt.BattleTransition, {
        _mesh = {}, -- rt.VertexShape
        _n_steps = which(n_tiles, 5),
        _width = 1,
        _height = 1,
        _offset = 0.1,
        _shader = rt.Shader("assets/shaders/battle_background.glsl"),
        _elapsed = 0,
        _triangles = {},
        _texture = nil
    })

    out:set_is_animated(true)
    return out
end)

--- @overload
function bt.BattleTransition:size_allocate(x, y, width, height)
    self._width = width
    self._height = height

    local n_steps = self._n_steps
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


    local x_scale = width / n_steps
    local y_scale = height / n_steps

    local triangles = {}
    function push(...)
        for x in range(...) do
            table.insert(triangles, x)
        end
    end

    -- upper most row
    for x_i = 1, n_steps + 1 - 1, 1 do

        local a = vertices:get(x_i, 1)
        local b = vertices:get(x_i + 1, 1)
        local c = {a[1], 0}

        push(
            {a[1] * x_scale, a[2] * y_scale},
             {b[1] * x_scale, b[2] * y_scale},
              {c[1] * x_scale, c[2] * y_scale}
        )

        a = vertices:get(x_i + 1, 1)
        b = vertices:get(x_i, 1)
        c = {a[1], 0}

        push(
            {a[1] * x_scale, a[2] * y_scale},
            {b[1] * x_scale, b[2] * y_scale},
            {c[1] * x_scale, c[2] * y_scale}
        )
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

                push(
                    {a[1] * x_scale, a[2] * y_scale},
                    {b[1] * x_scale, b[2] * y_scale},
                    {c[1] * x_scale, c[2] * y_scale}
                )

                a = vertices:get(x_i + 1, y_i)
                b = vertices:get(x_i + 1, y_i + 1)
                c = vertices:get(x_i, y_i + 1)

                push(
                    {a[1] * x_scale, a[2] * y_scale},
                    {b[1] * x_scale, b[2] * y_scale},
                    {c[1] * x_scale, c[2] * y_scale}
                )

            else
                a = vertices:get(x_i, y_i)
                b = vertices:get(x_i + 1, y_i)
                c = vertices:get(x_i + 1, y_i + 1)

                push(
                    {a[1] * x_scale, a[2] * y_scale},
                    {b[1] * x_scale, b[2] * y_scale},
                    {c[1] * x_scale, c[2] * y_scale}
                )

                a = vertices:get(x_i, y_i)
                b = vertices:get(x_i + 1, y_i + 1)
                c = vertices:get(x_i, y_i + 1)

                push(
                    {a[1] * x_scale, a[2] * y_scale},
                    {b[1] * x_scale, b[2] * y_scale},
                    {c[1] * x_scale, c[2] * y_scale}
                )
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

            push(
                {a[1] * x_scale, a[2] * y_scale},
                {b[1] * x_scale, b[2] * y_scale},
                {c[1] * x_scale, c[2] * y_scale}
            )
        else
            local a = vertices:get(x_i, y_index)
            local b = vertices:get(x_i + 1, y_index)
            local c = {a[1], b[2]}

            push(
                {a[1] * x_scale, a[2] * y_scale},
                {b[1] * x_scale, b[2] * y_scale},
                {c[1] * x_scale, c[2] * y_scale}
            )
        end
    end

    self._mesh = rt.VertexShape(triangles)
    self._mesh:set_draw_mode(rt.MeshDrawMode.TRIANGLES)
    self._mesh:set_texture(rt.Texture("assets/temp_wave.png"))

    local colors = {
        --rt.Palette.LIGHT_BLUE_1,
        rt.Palette.LIGHT_BLUE_2,
        rt.Palette.BLUE_1,
        rt.Palette.BLUE_2,
        rt.Palette.BLUE_3,
        rt.Palette.BLUE_4,
        rt.Palette.BLUE_5,
        --rt.Palette.BLUE_6
    }

    for i = 1, #triangles, 3 do
        --self._mesh:set_vertex_color(i, rt.HSVA(i / #triangles, 1, 1, 1))

        local color = colors[rt.random.integer(1, #colors)]
        for j = i, i + 2 do
            self._mesh:set_vertex_color(j, color)
        end
    end

    self._triangles = {}
    for _, p in pairs(triangles) do
        table.insert(self._triangles, p[1])
        table.insert(self._triangles, p[2])
    end
end

--- @overload
function bt.BattleTransition:draw()
    self._shader:bind()
    --love.graphics.setLineWidth(3)
    --love.graphics.setWireframe(true)
    self._mesh:draw()
    self._shader:unbind()
end

--- @overload
function bt.BattleTransition:update(delta)

    self._elapsed = self._elapsed + delta
    self._shader:send("_time", self._elapsed)
    --[[
    for _, polygon in pairs(self._triangles) do
        for i = 1, #polygon._vertices - 2, 2 do
            local x = polygon._vertices[i]
            local y = polygon._vertices[i+1]

            x = x + rt.random.number(-self._offset, self._offset)
            y = y + rt.random.number(-self._offset, self._offset)

            x = clamp(x, 0, self._width)
            y = clamp(y, 0, self._height)

            polygon._vertices[i] = x
            polygon._vertices[i+1] = y
        end
    end
    ]]--

--[[
    local offset = 1
    for x_i = 1, n_steps, 1 do
        for y_i = 1, n_steps, 1 do

            local v = vertices:get(x_i, y_i)
            if v[1] == 0 or v[1] == width or v[2] == 0 or v[2] == height then
                goto continue
            end

            v[1] = clamp(v[1] + rt.random.number(-offset, offset), 0, width)
            v[2] = clamp(v[2] + rt.random.number(-offset, offset), 0, height)

            ::continue::
        end
    end
    ]]--
end

--- @brief
function bt.BattleTransition:set_texture(texture)
    self._mesh:set_texture(texture)
end