require "include"

lt = {}

-- config
lt._lattice_size = { 300, 300 }

lt._kernel = {
    {1, 1, 1},
    {1, 2, 1},
    {1, 1, 1}
}

-- https://gist.github.com/slime73/079ef5d4e76cec6498ab7472b4f384d9
lt._step_shader = love.graphics.newComputeShader("lichen/step.glsl")
lt._render_texture_shader = love.graphics.newShader("lichen/render.glsl")


lt._initialized = false
lt._state_textures = {}  -- Tuple<love.Image, love.Image>
lt._step_input_order = true
lt._should_filter_state_textures = true

lt._state_textures = {}
lt._state_texture_format = "rgba16f"
lt._transform_in_place = true

lt.VertexFormat = {
    { name = "VertexPosition", format = "floatvec2" },
    { name = "VertexTexCoord", format = "floatvec2" },
    { name = "VertexColor",    format = "floatvec4" }
}
lt._lattice_shape = {} -- love.Mesh

--- @brief create new rectangle
lt.VertexRectangle = function(x, y, width, height)
    local w, h = width, height
    local out = love.graphics.newMesh(
        lt.VertexFormat,
        {
            { x + 0, y + 0,   0, 0,   1, 1, 1, 1 },
            { x + w, y + 0,   1, 0,   1, 1, 1, 1 },
            { x + w, y + h,   1, 1,   1, 1, 1, 1 },
            { x + 0, y + h,   0, 1,   1, 1, 1, 1 }
        },
        "triangles",
        "dynamic"
    )
    out:setVertexMap({
        1, 2, 3, 1, 3, 4
    })
    return out
end

lt._step_count = 0

function lt.initialize(width, height)
    lt._lattice_size = { width, height }
    lt._step_input_order = true

    -- initial lattice state
    local initial_data = love.image.newImageData(width, width, lt._state_texture_format)
    local pos_x = math.round(width / 2)
    local pos_y = math.round(height / 2)

    local growth = 0
    local width_center = width / 2 * rt.random.number(0.25, 0.75)
    local height_center = height / 2 * rt.random.number(0.25, 0.75)

    --[[
    for x = 1, width do
        for y = 1, height do
            if rt.random.toss_coin(0.005) then
                initial_data:setPixel(x - 1, y - 1,
                    rt.random.number(0, 1),
                    rt.random.number(0, 1),
                    rt.random.number(0, 1),
                    rt.random.number(0, 1)
                )
            end
        end
    end
    ]]--

    local function seed(x, y)
        x = x - 1
        y = y - 1
        for xi = -1, 1, 1 do
            for yi = -1, 1, 1 do
                initial_data:setPixel(x + xi, y + yi, xi, -1 * yi, 1, 0)
            end
        end
    end

    seed(0.33 * width, 0.33 * height)
    seed(0.66 * width, 0.66 * height)

    -- setup textures
    local texture_config = { computewrite = true }
    lt._state_textures[1] = love.graphics.newImage(initial_data, texture_config)

    if lt._transform_in_place then
        lt._state_textures[2] = lt._state_textures[1]
    else
        lt._state_textures[2] = love.graphics.newImage(initial_data, texture_config)
    end

    for i = 1, 2 do
        if lt._should_filter_state_textures == true then
            lt._state_textures[i]:setFilter("linear", "linear")
        else
            lt._state_textures[i]:setFilter("nearest", "nearest")
        end

        lt._state_textures[i]:setWrap("clampzero", "clampzero")
    end

    -- setup meshes
    lt._lattice_shape = lt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
    lt._lattice_shape:setTexture(lt._state_textures[1])

    lt._particle_shape = lt.VertexRectangle(
        0, 0,
            rt.graphics.get_width() / lt._lattice_size[1],
    rt.graphics.get_height() / lt._lattice_size[2]
    )
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
        computer:send("image_in", lt._state_textures[1])
        computer:send("image_out", lt._state_textures[2])
    else
        computer:send("image_in", lt._state_textures[2])
        computer:send("image_out", lt._state_textures[1])
    end

    --computer:send("kernel", lt._kernel)
    local rng = rt.random.number(0, 1)
    computer:send("rng", rng)

    love.graphics.dispatchThreadgroups(computer, lt._lattice_size[1], lt._lattice_size[2])

    if lt._step_input_order == true then
        lt._lattice_shape:setTexture(lt._state_textures[1])
    else
        lt._lattice_shape:setTexture(lt._state_textures[2])
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

    lt.initialize(lt._lattice_size[1], lt._lattice_size[2])
end

lt._is_stepping = false
lt._step_elapsed = 0
lt._steps_per_second = 15

love.keypressed = function(which)
    if which == "space" then
        lt._is_stepping = true
    elseif which == "up" then
        lt._steps_per_second = lt._steps_per_second + 10
    elseif which == "down" then
        lt._steps_per_second = lt._steps_per_second + 1
    else
        lt.step()
    end
end

love.keyreleased = function(which)
    if which == "space" then
        lt._is_stepping = false
        lt._step_elapsed = 0
    end
end

love.update = function(delta)
    if lt._is_stepping then
        lt._step_elapsed = lt._step_elapsed + delta
        while lt._step_elapsed > 1 / lt._steps_per_second do
            lt.step()
            lt._step_elapsed = lt._step_elapsed - 1 / lt._steps_per_second
        end
    end
end

love.draw = function()
    -- draw texture directly
    love.graphics.setShader(lt._render_texture_shader)
    love.graphics.draw(lt._lattice_shape)
end

love.resize = function()
    -- resize to screen size
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    lt._lattice_shape:setVertexAttribute(1, 1, 0, 0)
    lt._lattice_shape:setVertexAttribute(2, 1, w, 0)
    lt._lattice_shape:setVertexAttribute(3, 1, w, h)
    lt._lattice_shape:setVertexAttribute(4, 1, 0, h)
end