rt.settings.battle.quicksave_indicator = {
    duration = 3, -- seconds
}

--- @class bt.QuicksaveIndicator
bt.QuicksaveIndicator = meta.new_type("BattleQuicksaveIndicator", rt.Widget, function()
    local duration = rt.settings.battle.quicksave_indicator.duration
    return meta.new(bt.QuicksaveIndicator, {
        _frame = rt.Circle(0, 0, 1, 1),
        _frame_outline = rt.Circle(0, 0, 1, 1),
        _base = rt.Circle(0, 0, 1, 1),
        _frame_opacity = 0,
        _frame_snapshot = nil, -- rt.RenderTexture

        _screenshot = nil, -- rt.RenderTexture
        _mesh = nil, -- love.Mesh
        _n_vertices = 128,
        _paths = {}, -- Table<rt.Path>
        _texture_paths = {}, -- Table<rt.Path>

        _duration = duration,
        _value = 1,
        _direction = true, -- true: rectangle -> circle, false: circle -> rectangle

        _blur_shader = rt.Shader("battle/quicksave_indicator_blur.glsl"),
        _screenshot = nil
    })
end)

meta.add_signal(bt.QuicksaveIndicator, "done")

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
        {name = "VertexTexCoord", format = "floatvec2"}
    }

    --- @override
    function bt.QuicksaveIndicator:size_allocate(x, y, width, height)
        local center_x, center_y = x + 0.5 * width, y + 0.5 * height
        local x_radius, y_radius = 0.5 * width - self._thickness, 0.5 * height - self._thickness
        local m = rt.settings.margin_unit

        for shape in range(self._frame, self._frame_outline, self._base) do
            shape:resize(0.5 * width, 0.5 * height, x_radius, y_radius)
        end

        self._frame_snapshot = rt.RenderTexture(width, height, 4)
        self._frame_x = x
        self._frame_y = y
        love.graphics.push()
        love.graphics.origin()
        love.graphics.clear(true, false, false)
        self._frame_snapshot:bind()
        self._base:draw()
        self._frame_outline:draw()
        self._frame:draw()
        self._frame_snapshot:unbind()
        love.graphics.pop()

        local n_vertices = self._n_vertices

        local circle_vertices = {}
        local circle_texture_coordinates = {}
        local thickness = self._thickness + 2
        do -- generate circle
            local step = 2 * math.pi / n_vertices
            local offset = math.rad(-1 * (90 + 45))
            local screen_w, screen_h = love.graphics.getDimensions()
            for angle = 0, 2 * math.pi, step do
                table.insert(circle_vertices, {
                    0 + math.cos(angle + offset) * (x_radius - thickness),
                    0 + math.sin(angle + offset) * (y_radius - thickness)
                })

                table.insert(circle_texture_coordinates, {
                    0.5 + math.cos(angle + offset) * x_radius / width * (screen_h / screen_w),
                    0.5 + math.sin(angle + offset) * y_radius / height
                })
            end
        end

        local rectangle_vertices = {}
        local w, h = love.graphics.getDimensions()
        do
            local rectangle_x, rectangle_y = 0, 0
            local rectangle_top_path = rt.Path(
                rectangle_x, rectangle_y,
                rectangle_x + w, rectangle_y
            )

            local rectangle_right_path = rt.Path(
                rectangle_x + w, rectangle_y,
                rectangle_x + w, rectangle_y + h
            )

            local rectangle_bottom_path = rt.Path(
                rectangle_x + w, rectangle_y + h,
                rectangle_x, rectangle_y + h
            )

            local rectangle_left_path = rt.Path(
                rectangle_x, rectangle_y + h,
                rectangle_x, rectangle_y
            )

            local n_vertices_per_side = self._n_vertices / 4

            for path in range(
                rectangle_top_path,
                rectangle_right_path,
                rectangle_bottom_path,
                rectangle_left_path
            ) do
                for i = 1, n_vertices_per_side do
                    table.insert(rectangle_vertices, {path:at((i - 1) / n_vertices_per_side)})
                end
            end
        end

        self._paths = {}
        self._vertex_data = {}

        self._longest_path_length = NEGATIVE_INFINITY
        self._shortest_path_length = POSITIVE_INFINITY

        for i = 1, n_vertices do
            local rectangle_x, rectangle_y = table.unpack(rectangle_vertices[i])
            local circle_x, circle_y = table.unpack(circle_vertices[i])

            local path = rt.Path(
                rectangle_x, rectangle_y,
                0.5 * w + circle_x, 0.5 * h + circle_y,
                center_x + circle_x, center_y + circle_y
            )
            path:override_parameterization(0.5, 0.5)
            table.insert(self._paths, path)

            local texture_path = rt.Path(
                rectangle_x / w, rectangle_y / h,
                table.unpack(circle_texture_coordinates[i])
            )
            table.insert(self._texture_paths, texture_path)

            self._longest_path_length = math.max(self._longest_path_length, path:get_length())
            self._shortest_path_length = math.min(self._shortest_path_length, path:get_length())

            local hue = i / n_vertices
            table.insert(self._vertex_data, {
                center_x + circle_x, center_y + circle_y,
                rectangle_x / w, rectangle_y / h
            })
        end

        self._mesh = love.graphics.newMesh(_vertex_format, self._vertex_data, rt.MeshDrawMode.TRIANGLE_FAN)
        if self._render_texture_a ~= nil then self._mesh:setTexture(self._render_texture_a._native) end
    end

    --- @override
    function bt.QuicksaveIndicator:update(delta)
        local step = delta * (1 / self._duration)
        local before = self._value
        if self._direction then
            self._value = self._value + step
            if before < 1 and self._value >= 1 then
                self:signal_emit("done")
            end
        else
            self._value = self._value - step
            if before > 0 and self._value <= 0 then
                self:signal_emit("done")
            end
        end
        self._value = clamp(self._value, 0, 1)
        local value = rt.InterpolationFunctions.SIGMOID(self._value)
        self._frame_opacity = rt.InterpolationFunctions.SINUSOID_EASE_IN(2 * self._value)
        self._blur_strength = rt.InterpolationFunctions.EXPONENTIAL_ACCELERATION(self._value) * 20

        local should_update =
            (self._direction == true and self._value < 1) or
            (self._direction == false and self._value > 0)

        if should_update then
            for i = 1, self._n_vertices do
                local x, y = self._paths[i]:at(value)
                local tx, ty = self._texture_paths[i]:at(value)
                local data = self._vertex_data[i]
                data[1] = x
                data[2] = y
                data[3] = tx
                data[4] = ty
            end

            self._mesh:setVertices(self._vertex_data)
        end
    end
end

--- @override
function bt.QuicksaveIndicator:draw()
    if self._is_visible == true and self._mesh ~= nil and self._screenshot ~= nil then
        love.graphics.setColor(1, 1, 1, self._frame_opacity)
        love.graphics.draw(self._frame_snapshot._native, self._frame_x, self._frame_y)
    end
end

--- @brief
function bt.QuicksaveIndicator:draw_mesh()
    -- needs to be drawn separately, so it can be on top of entire scene
    if self._is_visible == true and self._mesh ~= nil and self._screenshot ~= nil then
        self._blur_shader:bind()
        self._blur_shader:send("radius", self._blur_strength)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self._mesh)
        self._blur_shader:unbind()
    end
end

--- @brief
function bt.QuicksaveIndicator:set_is_expanded(b)
    self._direction = not b
end

--- @brief
function bt.QuicksaveIndicator:get_is_expanded()
    return not self._direction
end

--- @brief
function bt.QuicksaveIndicator:skip()
    if self._direction == true then
        self._value = 1
    else
        self._value = 0
    end
    self:update(0)
end

--- @brief
function bt.QuicksaveIndicator:set_screenshot(texture)
    if texture == nil then
        self._mesh:setTexture(nil)
    else
        meta.assert_isa(texture, rt.RenderTexture)
        local next_w, next_h = texture:get_size()
        self._screenshot = texture
        self._mesh:setTexture(self._screenshot._native)
    end
end


