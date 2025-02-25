--- @class rt.Plot1D
rt.Plot1D = meta.new_type("Plot1D", rt.Widget, function(data, interpolate)
    interpolate = which(interpolate, true)

    local min, max = table.min_max(data._data)
    local out = meta.new(rt.Plot1D, {
        _spline = {}, -- rt.Spline
        _shape = {}, -- rt.VertexShape
        _zero = {},  -- rt.VertexShape
        _background = rt.VertexRectangle(0, 0, 1, 1),
        _data = data,
        _min = min,
        _max = max,
        _interpolate = interpolate,
        _width = data:get_dimension(1),
        _height = data:get_dimension(2),
        _line_visible = true,
        _points_visible = true
    })

    out._background:set_color(rt.Palette.BACKGROUND)
    return out
end)

--- @class rt.Plot2D
--- @param data rt.Matrix
rt.Plot2D = meta.new_type("Plot2D", rt.Widget, function(data)
    local out = meta.new(rt.Plot2D, {
        _texture = {},
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _width = data:get_dimension(1),
        _height = data:get_dimension(2)
    })

    local image = rt.Image(out._width, out._height)
    local min, max = table.min_max(data._data)
    for row_i = 1, out._height do
        for col_i = 1, out._width do
            local value = data:get(col_i, row_i)
            image:set_pixel(col_i, row_i, rt.HSVA((value - min) / (max - min), 1, 1, 1))
        end
    end

    out._texture = rt.Texture(image)
    out._texture:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out._texture:set_wrap_mode(rt.TextureWrapMode.CLAMP)
    out._shape:set_texture(out._texture)
    return out
end)

--- @brief
function rt.Plot1D:set_line_visible(b)
    self._line_visible = b
end

--- @brief
function rt.Plot1D:set_points_visible(b)
    self._points_visible = b
end

--- @overload
function rt.Plot1D:draw()
    self._background:draw()
    self._zero:draw()

    if self._line_visible then
        self._shape:draw()
    end

    if self._points_visible then
        for _, point in pairs(self._points) do
            point:draw()
        end
    end
end

--- @overload
function rt.Plot1D:size_allocate(x, y, width, height)
    self._background:set_vertex_position(1, x, y)
    self._background:set_vertex_position(2, x + width, y)
    self._background:set_vertex_position(3, x + width, y + height)
    self._background:set_vertex_position(4, x, y + height)

    local margin = 5 * rt.settings.margin_unit
    height = height - 2 * margin
    y = y + margin

    self._points = {}

    local vertices = {}
    local n = self._data:get_dimension(1)
    local range = ternary(self._max == self._min, 1, (self._max - self._min))
    for i = 1, n do
        local pos_x = x + (i - 1) * (width / (n - 1))
        local pos_y = y + (self._data:get(i) - self._min) / range * height
        table.insert(vertices, pos_x)
        table.insert(vertices, pos_y)

        table.insert(self._points, rt.VertexCircle(pos_x, pos_y, 4, 4))
    end


    self._zero = rt.VertexRectangleSegments(1, {
        x, y + (0 - self._min) / range * height,
        x + width, y + (0 - self._min) / range * height
    })
    self._zero:set_color(rt.Palette.GRAY_3)
    self._spline = rt.Spline(vertices, false, ternary(self._interpolate, 5, 1))
    self._shape = rt.VertexRectangleSegments(1, self._spline._vertices)
end

--- @overload
function rt.Plot2D:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @overload
function rt.Plot2D:draw()
    self._shape:draw()
end
