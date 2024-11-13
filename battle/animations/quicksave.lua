--- @class bt.Animation.QUICKSAVE
bt.Animation.QUICKSAVE = meta.new_type("QUICKSAVE", rt.Animation, function(scene)
    local screen_w, screen_h = love.graphics.getDimensions()
    local scale_duration = 2
    local hold_duration = 3
    local fade_out_duration = 0.5
    return meta.new(bt.Animation.QUICKSAVE, {
        _scene = scene,
        _screenshot = rt.RenderTexture(screen_w, screen_h, 0, "rgba4"),
        _n_vertices = 32,
        _vertex_data = {},
        _mesh = nil, -- love.mesh
        _vertex_paths = {}, -- Table<rt.Path>
        _blur_shader = rt.Shader("battle/animations/quicksave_blur.glsl"),
        _path_timer = rt.TimedAnimation(scale_duration, 0, 1, rt.InterpolationFunctions.SINUSOID_EASE_OUT),
        _hold_timer = rt.TimedAnimation(3),
        _shade = rt.VertexRectangle(0, 0, screen_w, screen_h),
        _shade_factor = 0,
        _shade_factor_animation = rt.TimedAnimation(
            scale_duration + hold_duration,
            1, 1 - 0.8,
            rt.InterpolationFunctions.SHELF, 0.8
        ),
        _started = false
    })
end)

--- @override
function bt.Animation.QUICKSAVE:start()
    self._vertex_data = {}

    local m = rt.settings.margin_unit
    local circle_r = 3 * m
    local circle_x, circle_y = love.graphics.getWidth() - (2 * m + circle_r), love.graphics.getHeight() - (2 * m + circle_r)
    local circle_vertices = {}
    local step = 2 * math.pi / self._n_vertices
    local offset = math.rad(-1 * (90 + 45))
    for angle = 0, 2 * math.pi, step do
        table.insert(circle_vertices, {
            circle_x + math.cos(angle + offset) * circle_r,
            circle_y + math.sin(angle + offset) * circle_r
        })
    end

    local rectangle_w, rectangle_h = love.graphics.getDimensions()
    local rectangle_x, rectangle_y = 0, 0
    local rectangle_top_path = rt.Path(
        rectangle_x, rectangle_y,
        rectangle_x + rectangle_w, rectangle_y
    )

    local rectangle_right_path = rt.Path(
        rectangle_x + rectangle_w, rectangle_y,
        rectangle_x + rectangle_w, rectangle_y + rectangle_h
    )

    local rectangle_bottom_path = rt.Path(
        rectangle_x + rectangle_w, rectangle_y + rectangle_h,
        rectangle_x, rectangle_y + rectangle_h
    )

    local rectangle_left_path = rt.Path(
        rectangle_x, rectangle_y + rectangle_h,
        rectangle_x, rectangle_y
    )

    local n_vertices_per_side = self._n_vertices / 4
    local rectangle_vertices = {}

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

    self._vertex_data = {}
    for i = 1, self._n_vertices do
        local x, y = table.unpack(rectangle_vertices[i])
        local texture_x, texture_y = x / rectangle_w, y / rectangle_h
        table.insert(self._vertex_data, {
            x, y, texture_x, texture_y
        })
    end

    local vertex_format = {
        {name = "VertexPosition", format = "floatvec2"},
        {name = "VertexTexCoord", format = "floatvec2"},
    }
    self._mesh = love.graphics.newMesh(vertex_format, self._vertex_data, rt.MeshDrawMode.TRIANGLE_FAN)

    self._vertex_paths = {}
    for i = 1, self._n_vertices do
        local from_x, from_y = table.unpack(rectangle_vertices[i])
        local to_x, to_y = table.unpack(circle_vertices[i])
        table.insert(self._vertex_paths, rt.Path(from_x, from_y, to_x, to_y))
    end

    self._screenshot:bind()
    self._scene:draw()
    self._screenshot:unbind()
    self._mesh:setTexture(self._screenshot._native)
    self._screenshot:set_scale_mode(rt.TextureScaleMode.LINEAR)
    self._started = true
end

--- @override
function bt.Animation.QUICKSAVE:finish()

end

--- @override
function bt.Animation.QUICKSAVE:update(delta)
    if self._path_timer:update(delta) then
        self._hold_timer:update(delta)
    end

    self._shade_factor_animation:update(delta)
    self._shade_factor = self._shade_factor_animation:get_value()

    local t = self._path_timer:get_value()
    self._blur_shader:send("strength", t)
    for i = 1, self._n_vertices do
        local x, y = self._vertex_paths[i]:at(t)
        self._vertex_data[i][1] = x
        self._vertex_data[i][2] = y
    end
    --self._mesh:setVertices(self._vertex_data)
    return self._path_timer:get_is_done() and
        self._hold_timer:get_is_done() and
        self._shade_factor_animation:get_is_done()
end

--- @override
function bt.Animation.QUICKSAVE:draw()
    if self._started ~= true then return end

    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
    love.graphics.setColor(self._shade_factor, self._shade_factor, self._shade_factor, 1)
    love.graphics.draw(self._shade._native)
    rt.graphics.set_blend_mode()

    self._blur_shader:bind()
    love.graphics.draw(self._mesh)
    self._blur_shader:unbind()
end
