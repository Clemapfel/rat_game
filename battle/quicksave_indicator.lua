rt.settings.battle.quicksave_indicator = {
    duration = 3, -- seconds
    max_blur = 20,
    n_vertices = 128
}

--- @class bt.QuicksaveIndicator
bt.QuicksaveIndicator = meta.new_type("BattleQuicksaveIndicator", rt.Widget, function()
    return meta.new(bt.QuicksaveIndicator, {
        _frame = rt.Circle(0, 0, 1, 1),
        _frame_outline = rt.Circle(0, 0, 1, 1),
        _base = rt.Circle(0, 0, 1, 1),
        _frame_opacity = 0,
        _frame_snapshot = nil, -- rt.RenderTexture
        _thickness = rt.settings.frame.thickness,

        _n_turns_elapsed = 0,
        _n_turns_label = nil, -- rt.Label

        _screenshot = nil, -- rt.RenderTexture
        _mesh = nil, -- love.Mesh
        _paths = {}, -- Table<rt.Path>
        _texture_paths = {}, -- Table<rt.Path>
        _n_vertices = rt.settings.battle.quicksave_indicator.n_vertices,
        _duration = rt.settings.battle.quicksave_indicator.duration,
        _value = 1,
        _direction = true, -- true: rectangle -> circle, false: circle -> rectangle

        _blur_shader = rt.Shader("battle/quicksave_indicator_blur.glsl"),
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

    self._n_turns_label = rt.Label(
        "<b><o>" .. self._n_turns_elapsed .. "</o></b>"--,
        --rt.settings.font.default_large,
        --rt.settings.font.default_mono_large
    )

    self._n_turns_label:realize()
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

        local local_center_x, local_center_y = 0.5 * width, 0.5 * height
        for shape in range(self._frame, self._frame_outline, self._base) do
            shape:resize(local_center_x, local_center_y, x_radius, y_radius)
        end

        local label_w, label_h = self._n_turns_label:measure()
        local label_x = local_center_x + x_radius - label_w
        local label_y = local_center_y + y_radius - 0.75 * label_h
        self._n_turns_label:fit_into(label_x, label_y)

        local padding = rt.settings.label.outline_offset_padding
        self._frame_snapshot = rt.RenderTexture(
            width + label_w + padding,
            height + label_h + padding,
            4
        )
        
        self._frame_x = x
        self._frame_y = y
        love.graphics.push()
        love.graphics.origin()
        self._frame_snapshot:bind()
        self._base:draw()
        self._frame_outline:draw()
        self._frame:draw()
        self._n_turns_label:draw()
        self._frame_snapshot:unbind()
        love.graphics.pop()

        local n_vertices = self._n_vertices
        local thickness = self._thickness + 2

        local circle_vertices = {}
        local circle_texture_coordinates = {}
        do
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

            local n_vertices_per_side = n_vertices / 4

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

            local hue = i / n_vertices
            table.insert(self._vertex_data, {
                center_x + circle_x, center_y + circle_y,
                rectangle_x / w, rectangle_y / h
            })
        end

        self._mesh = love.graphics.newMesh(_vertex_format, self._vertex_data, rt.MeshDrawMode.TRIANGLE_FAN)
        if self._screenshot ~= nil then self._mesh:setTexture(self._screenshot._native) end
    end
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
    local fs = rt.InterpolationFunctions
    local path_value = fs.SIGMOID(self._value)
    self._frame_opacity = fs.SINUSOID_EASE_IN(2 * self._value)
    self._blur_strength = fs.EXPONENTIAL_ACCELERATION(self._value) * rt.settings.battle.quicksave_indicator.max_blur

    for i = 1, self._n_vertices do
        local data = self._vertex_data[i]
        data[1], data[2] = self._paths[i]:at(path_value)
        data[3], data[4] = self._texture_paths[i]:at(path_value)
    end

    self._mesh:setVertices(self._vertex_data)
end

--- @override
function bt.QuicksaveIndicator:draw()
    if self._is_visible == true and self._mesh ~= nil and self._screenshot ~= nil then
        love.graphics.setColor(1, 1, 1, self._frame_opacity)
        love.graphics.draw(self._frame_snapshot._native, self._frame_x, self._frame_y)
    end

    self:draw_mesh()
end

--- @brief
function bt.QuicksaveIndicator:draw_mesh()
    -- needs to be drawn separately, so it can be on top of entire scene
    if self._is_visible == true and self._mesh ~= nil and self._screenshot ~= nil then
        self._blur_shader:bind()
        self._blur_shader:send("radius", self._blur_strength) -- expensive, but max blur is for tiny area
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
        self._screenshot = nil
        if self._mesh ~= nil then
            self._mesh:setTexture(nil)
        end
    else
        meta.assert_isa(texture, rt.RenderTexture)
        self._screenshot = texture
        if self._mesh ~= nil then
            self._mesh:setTexture(self._screenshot._native)
        end
    end
end

--- @brief
function bt.QuicksaveIndicator:set_n_turns_elapsed(n)
    self._n_turns_elapsed = n
    if self._is_realized then
        self._n_turns_label:set_text("<b><o>" .. n .. "</o></b>")
    end
end 