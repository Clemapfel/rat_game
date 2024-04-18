require "include"

lt = {}

-- https://gist.github.com/slime73/079ef5d4e76cec6498ab7472b4f384d9
lt._step_shader = love.graphics.newComputeShader("lichen/step.glsl")
--lt._render_shader = love.graphics.newShader("lichen/render.glsl")

lt._image_format = "rgba32f"
lt._lattice_size = {}   -- Tuple<Number, Numbre>

lt._step_textures = {}  -- Tuple<love.Image, love.Image>
lt._step_input_order = true
lt._should_filter_step_textures = true

lt._render_shape = {} -- rt.VertexRectangle

function lt.initialize(size_x, size_y)
    lt._lattice_size = { size_x, size_y }
    lt._step_input_order = true

    local initial_data = love.image.newImageData(size_x, size_x, lt._image_format)
    for x = 1, size_x do
        for y = 1, size_y do
            local hue = rt.random.number(0, 1)
            initial_data:setPixel(x - 1, y - 1, hue, hue, hue, 1)
        end
    end

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

    local input, output
    if lt._step_input_order == true then
        computer:send("image_in", lt._step_textures[1])
        computer:send("image_out", lt._step_textures[2])
    else
        computer:send("image_in", lt._step_textures[2])
        computer:send("image_out", lt._step_textures[1])
    end

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
    lt._render_shape:draw()
end

love.resize = function()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    lt._render_shape:set_vertex_position(1, 0, 0)
    lt._render_shape:set_vertex_position(2, w, 0)
    lt._render_shape:set_vertex_position(3, w, h)
    lt._render_shape:set_vertex_position(4, 0, h)
end