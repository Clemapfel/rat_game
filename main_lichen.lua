require "include"

lt = {}

-- https://gist.github.com/slime73/079ef5d4e76cec6498ab7472b4f384d9
lt._step_shader = love.graphics.newComputeShader("lichen/step.glsl")
lt._render_shader = love.graphics.newShader("lichen/render.glsl")

lt._image_format = "rgba16f"
lt._lattice_size = {}   -- Tuple<Number, Numbre>

lt._initialized = false
lt._step_textures = {}  -- Tuple<love.Image, love.Image>
lt._step_input_order = true
lt._should_filter_step_textures = false

lt._render_shape = {} -- rt.VertexRectangle

lt._cell_size = 1
lt._max_state = 10
lt._max_growth = 75
lt._step_count = 0

function lt.initialize(width, height)
    lt._lattice_size = { width, height }
    lt._step_input_order = true

    -- initial lattice state
    local initial_data = love.image.newImageData(width, width, lt._image_format)
    for x = 1, width do
        for y = 1, height do
            initial_data:setPixel(x - 1, y - 1,
                0, -- state
                0, -- vector x
                0, -- vector y
                0 -- age
            )
        end
    end

    -- seed, cf. https://github.com/sleepokay/lichen/blob/1e3837aa8396521e5b46cf97a122e74504520f0c/lichen.pde#L39
    local pos_x = math.round(width / 2)
    local pos_y = math.round(height / 2)

    local cell_size = lt._cell_size
    local growth = 0
    local width_center = width / cell_size / 2
    local height_center = height / cell_size / 2

    local function set(x, y, state, vector_x, vector_y)
        initial_data:setPixel(
            x - 1, y - 1,
            vector_x,
            vector_y,
            state,
            0
        )
    end

    local max_state = lt._max_state
    set(width_center - 1, height_center + 0, max_state, -1, 0)
    set(width_center + 1, height_center + 0, max_state, 1, 0)
    set(width_center + 0, height_center - 1, max_state, 0, -1)
    set(width_center + 0, height_center + 1, max_state, 0, 1)
    set(width_center, height_center, max_state, 0, 0)

    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            dbg(x, y, (rt.angle(x, y) + math.pi) / (2 * math.pi))
        end
    end

    -- setup textures
    local texture_config = { computewrite = true }
    lt._step_textures[1] = love.graphics.newImage(initial_data, texture_config)
    lt._step_textures[2] = love.graphics.newImage(initial_data, texture_config)

    for i = 1, 2 do
        if lt._should_filter_step_textures == true then
            lt._step_textures[i]:setFilter("linear", "linear")
        else
            lt._step_textures[i]:setFilter("nearest", "nearest")
        end
    end

    lt._render_shape = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
    lt._render_shape._native:setTexture(lt._step_textures[1])
end

--- @brief step simulation
function lt.step()
    -- apply compute shader, swap input and output such that each
    -- step can be applied to itself to iteratively advance simulation
    local computer = lt._step_shader
    local group_count = (lt._lattice_size[1] * lt._lattice_size[2])
    lt._step_count = lt._step_count + 1

    local input, output
    if lt._step_input_order == true then
        computer:send("image_in", lt._step_textures[1])
        computer:send("image_out", lt._step_textures[2])
    else
        computer:send("image_in", lt._step_textures[2])
        computer:send("image_out", lt._step_textures[1])
    end

    --computer:send("cell_size", lt._cell_size)
    computer:send("max_state", lt._max_state)
    computer:send("time", lt._step_count)

--    computer:send("max_growth", lt._max_growth)

    love.graphics.dispatchThreadgroups(computer, lt._lattice_size[1], lt._lattice_size[2])

    if lt._step_input_order == true then
        lt._render_shape._native:setTexture(lt._step_textures[1])
    else
        lt._render_shape._native:setTexture(lt._step_textures[2])
    end

    lt._step_input_order = not lt._step_input_order
end

-- ### MAIN

love.load = function()
    love.window.setMode(1600 / 1.5, 900 / 1.5, {
        vsync = -1, -- adaptive vsync, may tear but tries to stay as close to 60hz as possible
        msaa = 8,
        stencil = true,
        resizable = true,
        borderless = false
    })
    love.window.setTitle("rat_game: lichen")
    love.filesystem.setIdentity("rat_game")

    lt.initialize(64, 64)
end

love.keypressed = function(which)
    lt.step()
end

love.draw = function()
    love.graphics.setShader(lt._render_shader)
    lt._render_shader:send("max_state", lt._max_state)
    lt._render_shape:draw()
end

love.resize = function()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    lt._render_shape:set_vertex_position(1, 0, 0)
    lt._render_shape:set_vertex_position(2, w, 0)
    lt._render_shape:set_vertex_position(3, w, h)
    lt._render_shape:set_vertex_position(4, 0, h)
end