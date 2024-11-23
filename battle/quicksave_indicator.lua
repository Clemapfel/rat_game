--- @class bt.QuicksaveIndicator
bt.QuicksaveIndicator = meta.new_type("BattleQuicksaveIndicator", rt.Widget, function()
    return meta.new(bt.QuicksaveIndicator, {
        _frame = rt.Circle(0, 0, 1, 1),
        _frame_outline = rt.Circle(0, 0, 1, 1),
        _base = rt.Circle(0, 0, 1, 1),
        _thickness = rt.settings.frame.thickness * 5,
        _gradient = nil, -- love.Mesh

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

--- @override
function bt.QuicksaveIndicator:size_allocate(x, y, width, height)
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height
    local x_radius, y_radius = 0.5 * width - self._thickness, 0.5 * height - self._thickness
    local m = rt.settings.margin_unit

    for shape in range(self._frame, self._frame_outline, self._base) do
        shape:resize(center_x, center_y, x_radius, y_radius)
    end

    -- generate mesh ring
    local vertices = {}
    local outer_color = rt.RGBA(1, 1, 1, 1)
    local inner_color_factor = 0.7
    local inner_color = rt.RGBA(inner_color_factor, inner_color_factor, inner_color_factor, 1)

    local n_outer_vertices = 8
    local step = 2 * math.pi / n_outer_vertices
    local n_vertices = 0
    for angle = 0, 2 * math.pi, step do
        table.insert(vertices, {
            center_x + math.cos(angle) * (x_radius - 0.5 * self._thickness),
            center_y + math.sin(angle) * (y_radius - 0.5 * self._thickness),
            0, 0,
            outer_color.r, outer_color.g, outer_color.b, outer_color.a
        })

        table.insert(vertices, {
            center_x + math.cos(angle + 0.25 * step) * (x_radius + 0.5 * self._thickness),
            center_y + math.sin(angle + 0.25 * step) * (y_radius + 0.5 * self._thickness),
            0, 0,
            inner_color.r, inner_color.g, inner_color.b, inner_color.a
        })

        n_vertices = n_vertices + 2
    end

    self._gradient = love.graphics.newMesh(vertices, rt.MeshDrawMode.TRIANGLES)

    local vertex_map = {}
    for i = 1, n_vertices - 3 do
        for index in range(
            i, i + 1, i + 2,
            i + 1, i + 2, i + 3
        ) do
            table.insert(vertex_map, index)
        end
    end

    for index in range(
        n_vertices - 1, n_vertices, 1,
        n_vertices, 1, 2
    ) do
        table.insert(vertex_map, index)
    end

    self._gradient:setVertexMap(vertex_map)
end

--- @override
function bt.QuicksaveIndicator:draw()
    --self._base:draw()
    --self._frame_outline:draw()
    --self._frame:draw()

    --rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
    love.graphics.setWireframe(true)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self._gradient)
    love.graphics.setWireframe(false)
    --rt.graphics.set_blend_mode()
end

--- @override
function bt.QuicksaveIndicator:set_screenshot(texture)
end

