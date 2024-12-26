require "include"

-- https://www.sciencedirect.com/science/article/pii/S0022169422010198?via%3Dihub

local texture_w, texture_h = 512, 512
local cell_texture_a, cell_texture_b, cell_offset_texture

local relaxation_factor = 0.5
local lattice_size = {texture_w, texture_h}
local a_or_b = true

local init_shader = rt.ComputeShader("main_blood_lattice_init.glsl")
local step_shader = rt.ComputeShader("main_blood_lattice_step.glsl")
local render_shader = rt.Shader("main_blood_lattice_render.glsl")
local render_shape = nil -- rt.VertexRectangle

love.load = function()
    love.window.setMode(texture_w, texture_h, {
        vsync = 0,
        resizable = true
    })
    love.resize(512, 512)

    cell_texture_a = love.graphics.newCanvas(texture_w, texture_h, {
        format = "rgba32f",
        computewrite = true
    })

    cell_texture_b = love.graphics.newCanvas(texture_w, texture_h, {
        format = "rgba32f",
        computewrite = true
    })

    cell_offset_texture = love.graphics.newCanvas(texture_w, texture_h, {
        format = "r32i",
        computewrite = true
    })

    for texture in range(cell_texture_a, cell_texture_b) do
        init_shader:send("cell_texture", texture)
        init_shader:send("mode", 1) -- init distance
        init_shader:dispatch(texture_w, texture_h)
        init_shader:send("mode", 2) -- init gradient
        init_shader:dispatch(texture_w, texture_h)
        init_shader:send("mode", 3) -- init hitboxes
        --init_shader:dispatch(texture_w, texture_h)
    end

    love.update(1 / 60)
end

love.update = function(delta)
    if not love.keyboard.isDown("space") then return end

    local texture_in, texture_out
    if a_or_b == true then
        texture_in, texture_out = cell_texture_a, cell_texture_b
    else
        texture_in, texture_out = cell_texture_b, cell_texture_a
    end

    step_shader:send("delta", 1 / 60) --delta)
    step_shader:send("cell_texture_in", texture_in)
    step_shader:send("cell_texture_out", texture_out)
    step_shader:send("cell_offset_texture", cell_offset_texture)

    step_shader:send("mode", 1) -- apply offset
    step_shader:dispatch(texture_w, texture_h)
    step_shader:send("mode", 2) -- compute offset
    step_shader:dispatch(texture_w, texture_h)

    --a_or_b = not a_or_b
end

love.resize = function(w, h)
    render_shape = rt.VertexRectangle(0, 0, w, h)
end

love.keypressed = function(which)
    if which == "b" then love.load() end
end

local temp_shader = love.graphics.newShader("main_blood_lattice_temp.glsl")

love.draw = function()
    love.graphics.setColor(1, 1, 1, 1)

    render_shader:bind()
    if a_or_b then
        render_shader:send("cell_texture", cell_texture_a)
    else
        render_shader:send("cell_texture", cell_texture_b)
    end
    render_shape:draw()
    render_shader:unbind()

    love.graphics.print(love.timer.getFPS(), 0, 0)
end