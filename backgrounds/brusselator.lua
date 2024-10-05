rt.Background.BRUSSELATOR = meta.new_type("BRUSSELATOR", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.BRUSSELATOR, {
        _textures = {},  -- Tuple<love.Texture, love.Texture>
        _texture_swap_state = true,

        _render_shader = rt.Shader("backgrounds/brusselator_render.glsl"),
        _compute_shader = rt.ComputeShader("backgrounds/brusselator_compute.glsl"),

        _resolution_x =1,
        _resolution_y = 1,
        _elapsed = 0,
        _n_updates_per_second = 60,
    })
end, {
    MODE_RENDER = 1,
    MODE_INITIALIZE = 2
})

--- @brief [internal]
do
    local settings = {
        computewrite = true,
        format = "rgba16f",

    }
    function rt.Background.BRUSSELATOR:_initialize_textures(x, y)
        self._textures[1] = love.graphics.newCanvas(self._resolution_x, self._resolution_y, settings)
        self._textures[2] = love.graphics.newCanvas(self._resolution_x, self._resolution_y, settings)
    end
end

--- @override
function rt.Background.BRUSSELATOR:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self:_initialize_textures(1,1)
end

--- @brief
function rt.Background.BRUSSELATOR:_get_input_output()
    if self._texture_swap_state == true then
        return self._textures[1], self._textures[2]
    else
        return self._textures[2], self._textures[1]
    end
end

--- @override
function rt.Background.BRUSSELATOR:size_allocate(x, y, width, height)
    self._resolution_x = rt.graphics.get_width()
    self._resolution_y = rt.graphics.get_height()

    for i in range(1, 2) do
        local w, h = self._textures[i]:getWidth(), self._textures[i]:getHeight()
        if w ~= self._resolution_x or h ~= self._resolution_y then
            self:_initialize_textures(w, h)
            break
        end
    end

    local input, output = self:_get_input_output()
    self._render_shader:bind()
    self._render_shader:send("mode", self.MODE_INITIALIZE)
    for texture in range(input, output) do
        love.graphics.setCanvas(texture)
        love.graphics.rectangle("fill", 0, 0, self._resolution_x, self._resolution_y)
        love.graphics.setCanvas()
    end
    self._render_shader:unbind()
end

--- @override
function rt.Background.BRUSSELATOR:update(delta)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta
    local step = 1 / self._n_updates_per_second
    while self._elapsed > step do
        self._elapsed = self._elapsed - step
        local input, output = self:_get_input_output()
        self._compute_shader:send("texture_in", input)
        self._compute_shader:send("texture_out", output)
        self._compute_shader:dispatch(self._resolution_x, self._resolution_y)
    end
end

--- @override
function rt.Background.BRUSSELATOR:draw()
    if self._is_realized ~= true then return end

    local input, output = self:_get_input_output()
    local shader = self._render_shader
    shader:bind()
    shader:send("mode", self.MODE_RENDER)
    love.graphics.draw(output, 0, 0)
    shader:unbind()
end
