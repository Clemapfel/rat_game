rt.settings.battle.quicksave_indicator = {
    duration = 2, -- seconds
}

--- @class bt.QuicksaveIndicator
bt.QuicksaveIndicator = meta.new_type("BattleQuicksaveIndicator", rt.Widget, function()
    local duration = rt.settings.battle.quicksave_indicator.duration
    return meta.new(bt.QuicksaveIndicator, {
        _frame = rt.Circle(0, 0, 1, 1),
        _frame_outline = rt.Circle(0, 0, 1, 1),
        _base = rt.Circle(0, 0, 1, 1),
        _thickness = rt.settings.frame.thickness * 5,

        _screenshot = nil, -- rt.RenderTexture
        _mesh = nil, -- love.Mesh
        _n_vertices = 128,
        _paths = {}, -- Table<rt.Path>

        _duration = duration,
        _value = 0,
        _direction = true -- true: rectangle -> circle, false: circle -> rectangle
    })
end)

--- @override
function bt.QuicksaveIndicator:realize()
    if self:already_realized() then return end

    self._frame:set_color(rt.Palette.FOREGROUND)
    self._frame_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    self._base:set_color(rt.Palette.BACKGROUND)

    self._frame:set_line_width(self._thickness)
    self._frame_outline:set_line_width(self._thickness + 2)

    self._frame:set_is_outline(true)
    self._frame_outline:set_is_outline(true)
    self._base:set_is_outline(false)
end

do
    local _vertex_format = {
        {name = "VertexPosition", format = "floatvec2"},
        {name = "VertexTexCoord", format = "floatvec2"},
        {name = "VertexColor", format = "floatvec4"},
    }

    --- @override
    function bt.QuicksaveIndicator:size_allocate(x, y, width, height)
        local center_x, center_y = x + 0.5 * width, y + 0.5 * height
        local x_radius, y_radius = 0.5 * width - self._thickness, 0.5 * height - self._thickness
        local m = rt.settings.margin_unit

        for shape in range(self._frame, self._frame_outline, self._base) do
            shape:resize(center_x, center_y, x_radius, y_radius)
        end

        local n_vertices = self._n_vertices

        local circle_vertices = {}
        do -- generate circle
            local step = 2 * math.pi / n_vertices
            local offset = math.rad(-1 * (90 + 45))
            for angle = 0, 2 * math.pi, step do
                table.insert(circle_vertices, {
                    center_x + math.cos(angle + offset) * x_radius,
                    center_y + math.sin(angle + offset) * y_radius
                })
            end
        end

        local rectangle_vertices = {}
        -- generate equally spaced vertices around rectangle perimeter
        local w, h = love.graphics.getDimensions()
        local x_step = w / (n_vertices / 4)
        local y_step = h / (n_vertices / 4)

        table.insert(rectangle_vertices, {0, 0})
        for x = x_step, w - x_step, x_step do
            table.insert(rectangle_vertices, {x, 0})
        end

        table.insert(rectangle_vertices, {w, 0})
        for y = y_step, h - y_step, y_step do
            table.insert(rectangle_vertices, {w, y})
        end

        table.insert(rectangle_vertices, {w, h})
        for x = x_step, w - x_step, x_step do
            table.insert(rectangle_vertices, {x, h})
        end

        table.insert(rectangle_vertices, {0, h})
        for y = y_step, h - y_step, y_step do
            table.insert(rectangle_vertices, {0, y})
        end

        self._paths = {}
        self._vertex_data = {}

        for i = 1, n_vertices do
            local rectangle_x, rectangle_y = table.unpack(rectangle_vertices[i])
            local circle_x, circle_y = table.unpack(circle_vertices[i])
            table.insert(self._paths, rt.Path(
                rectangle_x, rectangle_y, circle_x, circle_y
            ))

            local hue = i / n_vertices
            table.insert(self._vertex_data, {
                rectangle_x, rectangle_y,
                rectangle_x / w, rectangle_y / h,
                rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(hue, 1, 1, 1)))
            })
        end

        self._mesh = love.graphics.newMesh(_vertex_format, self._vertex_data, rt.MeshDrawMode.TRIANGLE_FAN)
        if self._screenshot ~= nil then self._mesh:setTexture(self._screenshot._native) end
    end

    --- @override
    function bt.QuicksaveIndicator:update(delta)

        local step = delta * (1 / self._duration)
        if self._direction then
            self._value = self._value + step
        else
            self._value = self._value - step
        end
        self._value = clamp(self._value, 0, 1)

        local should_update =
            (self._direction == true and self._value < 1) or
            (self._direction == false and self._value > 0)

        if should_update then
            for i = 1, self._n_vertices do
                local x, y = self._paths[i]:at(self._value)
                local data = self._vertex_data[i]
                data[1] = x
                data[2] = y
            end

            self._mesh:setVertices(self._vertex_data)
        end
    end
end

--- @override
function bt.QuicksaveIndicator:draw()
    self._base:draw()
    self._frame_outline:draw()
    self._frame:draw()

    if self._mesh ~= nil then love.graphics.draw(self._mesh) end
end

--- @brief
function bt.QuicksaveIndicator:set_is_expanded(b)
    self._direction = b
end

--- @brief
function bt.QuicksaveIndicator:get_is_expanded()
    return self._direction
end

--- @brief
function bt.QuicksaveIndicator:set_screenshot(texture)
    if texture == nil then
        self._mesh:setTexture(nil)
    else
        meta.assert_isa(texture, rt.RenderTexture)
        self._mesh:setTexture(texture._native)
    end
end


