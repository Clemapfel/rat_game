rt.settings.battle.background.sdf_meatballs = {
    resolution_factor = 0.6,
    n_cycles_per_second = 60,
}

bt.Background.SDF_MEATBALLS = meta.new_type("SDF_MEATBALLS", bt.Background, function()
    return meta.new(bt.Background.SDF_MEATBALLS, {
        _output_textures = {},  -- Tuple<love.Texture, love.Texture>
        _data = {
            circles = {},  -- love.image
            n_circles = 0,
        },

        _shape = {},    -- rt.VertexRectangle

        _resolution_x = 1,
        _resolution_y = 1,
        _elapsed = 0,
        _elapsed_total = 0
    })
end)

--- @override
function bt.Background.SDF_MEATBALLS:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local resolution_factor = rt.settings.battle.background.sdf_meatballs.resolution_factor
    self._resolution_x = resolution_factor * rt.graphics.get_width()
    self._resolution_y = resolution_factor * rt.graphics.get_height()

    self._step_shader = love.graphics.newComputeShader("battle/backgrounds/sdf_meatballs_compute.glsl")
    self._render_shader = rt.Shader("battle/backgrounds/sdf_meatballs_render.glsl")

    local texture_format = "rgba32f"
    local texture_config = { computewrite = true }
    local initial_data = love.image.newImageData(self._resolution_x, self._resolution_y, texture_format)

    self._sdf_texture = love.graphics.newImage(initial_data, texture_config)
    self._shape = rt.VertexRectangle(0, 0, 1, 1)

    local n_circles = 35
    local w, h = self._resolution_x, self._resolution_y
    local circle_data = love.image.newImageData(self._resolution_x, self._resolution_y, "rgba32f")
    local padding = 0.05
    for i = 1, n_circles do
        local center_x, center_y = rt.random.integer(padding * w, w - padding * w), rt.random.integer(padding * h, h - padding * h)
        local radius = rt.random.number(0.01, 0.02)
        local hue = rt.random.number(0, 1)
        circle_data:setPixel(i, 1, center_x, center_y, radius, hue)
    end
    self._data.circles_data = circle_data
    self._data.circles = love.graphics.newImage(circle_data, texture_config)
    self._data.n_circles = n_circles
end

--- @override
function bt.Background.SDF_MEATBALLS:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.SDF_MEATBALLS:update(delta, intensity)
    if self._is_realized ~= true then return end

    self._elapsed = self._elapsed + delta
    self._elapsed_total = self._elapsed_total + delta

    local n_circles = self._data.n_circles
    local circle_data = self._data.circles_data
    for i = 1, n_circles do
        local center_x, center_y, radius, angle = circle_data:getPixel(i, 1)
        center_x, center_y = rt.translate_point_by_angle(center_x, center_y, radius * delta, angle)
        angle = angle + delta * (math.pi / 32)
        radius = radius + math.sin(self._elapsed_total) * 0.0001
        circle_data:setPixel(i, 1, center_x, center_y, radius, angle)
    end
    self._data.circles:replacePixels(circle_data)

    local cycle_duration = 1 / rt.settings.battle.background.sdf_meatballs.n_cycles_per_second
    while self._elapsed > cycle_duration do
        self._elapsed = self._elapsed - cycle_duration

        local shader = self._step_shader
        shader:send("sdf_out", self._sdf_texture)
        shader:send("resolution", {self._resolution_x, self._resolution_y})
        shader:send("elapsed", self._elapsed_total)
        --shader:send("circles", self._data.circles)
        --shader:send("n_circles", self._data.n_circles)
        love.graphics.dispatchThreadgroups(shader, self._resolution_x, self._resolution_y)
    end
end

--- @override
function bt.Background.SDF_MEATBALLS:draw()
    if self._is_realized ~= true then return end

    local shader = self._render_shader
    shader:bind()
    shader:send("sdf_texture", self._sdf_texture)
    self._shape:draw()
    shader:unbind()
end
