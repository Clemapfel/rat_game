rt.Background.VECTOR_FIELD = meta.new_type("VECTOR_FIELD", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.VECTOR_FIELD, {
        _textures = {},  -- Tuple<love.Texture, love.Texture>
        _texture_swap_state = true,

        _render_shader = rt.Shader("backgrounds/vector_field_render.glsl"),
        _compute_shader = rt.ComputeShader("backgrounds/vector_field_compute.glsl"),

        _resolution_x =1,
        _resolution_y = 1,
        _elapsed = 0,
        _n_updates_per_second = 60,
    })
end, {
    MODE_RENDER = 1,
    MODE_INITIALIZE = 2
})

--- @override
function rt.Background.VECTOR_FIELD:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local settings = {
        computewrite = true,
        format = "rg32f"
    }
    self._textures[1] = love.graphics.newImage(self._resolution_x, self._resolution_y, settings)
    self._textures[2] = love.graphics.newImage(self._resolution_x, self._resolution_y, settings)
end

--- @brief
function rt.Background.VECTOR_FIELD:_get_input_output()
    if self._texture_swap_state == true then
        return self._textures[1], self._textures[2]
    else
        return self._textures[2], self._textures[1]
    end
end

--- @override
function rt.Background.VECTOR_FIELD:size_allocate(x, y, width, height)
    self._resolution_x = rt.graphics.get_width()
    self._resolution_y = rt.graphics.get_height()

    for i in range(1, 2) do
        local w, h = self._textures[i]:getWidth(), self._textures[i]:getHeight()
        if w ~= self._resolution_x or h ~= self._resolution_y then
            self._textures[i] = rt.RenderTexture(self._resolution_x, self._resolution_y)
        end
    end

    local input, output = self:_get_input_output()
    self._render_shader:bind()
    self._render_shader:send("mode", self.MODE_RENDER)
    for texture in range(input, output) do
        texture:bind_as_render_target()
        love.graphics.rectangle("fill", 0, 0, self._resolution_x, self._resolution_y)
        texture:unbind_as_render_target()
    end
    self._render_shader:unbind()
end

--- @override
function rt.Background.VECTOR_FIELD:update(delta)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta
    local step = 1 / self._n_updates_per_second
    while self._elapsed > step do
        self._elapsed = self._elapsed - step
        local input, output = self:_get_input_output()
        self._compute_shader:send("texture_in", input._native)
        self._compute_shader:send("texture_out", output._native)
        self._compute_shader:dispatch(self._resolution_x, self._resolution_y)
    end
end

--- @override
function rt.Background.VECTOR_FIELD:draw()
    if self._is_realized ~= true then return end

    local input, output = self:_get_input_output()
    local shader = self._render_shader
    shader:bind()
    shader:send("mode", self.MODE_RENDER)
    output:draw(0, 0)
    shader:unbind()
end
