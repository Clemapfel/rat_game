rt.Background.BRUSSELATOR = meta.new_type("BRUSSELATOR", rt.BackgroundImplementation, function()
    local defines =  {
        defines = {
            TEXTURE_FORMAT = rt.Background.BRUSSELATOR.texture_format
        }
    }
    return meta.new(rt.Background.BRUSSELATOR, {
        _textures = {},  -- Tuple<love.Texture, love.Texture>
        _texture_swap_state = true,

        _render_shader = rt.Shader("backgrounds/brusselator_render.glsl", defines),
        _initialize_shader = rt.ComputeShader("backgrounds/brusselator_initialize.glsl", defines),
        _compute_shader = rt.ComputeShader("backgrounds/brusselator_compute.glsl", defines),

        _resolution_x =1,
        _resolution_y = 1,
        _elapsed = 0,
        _n_updates_per_second = 60,
    })
end, {

    texture_format = "rg32f",

    a = 3,
    b = 9,
    diffusivity = {1, 0.1},
    perturbation = 0.5,
    scale = 20

    --[[
    a = 1,
    b = 3,
    diffusivity = {1, 0.1},
    perturbation = 0.1
    ]]--
})

--- @brief [internal]
function rt.Background.BRUSSELATOR:_initialize_textures(x, y)
    local settings = {
        computewrite = true,
        format = self.texture_format,
    }

    self._textures[1] = love.graphics.newCanvas(self._resolution_x, self._resolution_y, settings)
    self._textures[2] = love.graphics.newCanvas(self._resolution_x, self._resolution_y, settings)

    --self._initialize_shader:send("a", self.a)
    --self._initialize_shader:send("b", self.b)
    --self._initialize_shader:send("perturbation", self.perturbation)
    --self._initialize_shader:send("scale", self.scale)
    for texture in values(self._textures) do
        texture:setWrap(rt.TextureWrapMode.CLAMP)
        self._initialize_shader:send("texture_out", texture)
        self._initialize_shader:dispatch(self._resolution_x, self._resolution_y)
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
            self:_initialize_textures(self._resolution_x, self._resolution_y)
            break
        end
    end
end

--- @override
function rt.Background.BRUSSELATOR:update(delta)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta
    local step = 1 / self._n_updates_per_second
    while self._elapsed > step do
        self._elapsed = self._elapsed - step
        local input, output = self:_get_input_output()
        self._compute_shader:send("a", self.a)
        self._compute_shader:send("b", self.b)
        self._compute_shader:send("diffusivity", self.diffusivity)
        self._compute_shader:send("texture_in", input)
        self._compute_shader:send("texture_out", output)
        self._compute_shader:send("delta", delta)
        --self._compute_shader:dispatch(self._resolution_x, self._resolution_y)
        self._texture_swap_state = not self._texture_swap_state
    end
end

--- @override
function rt.Background.BRUSSELATOR:draw()
    if self._is_realized ~= true then return end

    local input, output = self:_get_input_output()
    local shader = self._render_shader
    shader:bind()
    love.graphics.draw(output, 0, 0)
    shader:unbind()
end
