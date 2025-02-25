require "include"

-- https://www.sciencedirect.com/science/article/pii/S0022169422010198?via%3Dihub

local texture_w, texture_h = 800, 800
local cell_texture_a, cell_texture_b -- r:depth, g:x-velocity, b:y-velocity, a:elevation
local flux_texture_top_a, flux_texture_top_b -- x: top-left, y:top, z:top-right
local flux_texture_center_a, flux_texture_center_b -- x: left, y: center, z: right
local flux_texture_bottom_a, flux_texture_bottom_b -- x: bottom-left, y:bottom, z:bottom_right

local relaxation_factor = 0.5
local lattice_size = {texture_w, texture_h}
local a_or_b = true

local init_shader
local step_shader
local render_shader
local render_shape = nil -- rt.VertexRectangle

love.load = function()
    love.window.setMode(texture_w, texture_h, {
        vsync = 0,
        resizable = true
    })
    love.resize(texture_w, texture_w)

    init_shader = rt.ComputeShader("main_blood_lattice_init.glsl")
    step_shader = rt.ComputeShader("main_blood_lattice_step.glsl")
    render_shader = rt.Shader("main_blood_lattice_render.glsl")

    local config = {
        format = "rgba32f",
        computewrite = true
    }

    cell_texture_a = love.graphics.newCanvas(texture_w, texture_h, config)
    cell_texture_b = love.graphics.newCanvas(texture_w, texture_h, config)

    flux_texture_top_a = love.graphics.newCanvas(texture_w, texture_h, config)
    flux_texture_top_b = love.graphics.newCanvas(texture_w, texture_h, config)

    flux_texture_center_a = love.graphics.newCanvas(texture_w, texture_h, config)
    flux_texture_center_b = love.graphics.newCanvas(texture_w, texture_h, config)

    flux_texture_bottom_a = love.graphics.newCanvas(texture_w, texture_h, config)
    flux_texture_bottom_b = love.graphics.newCanvas(texture_w, texture_h, config)

    init_shader:send("cell_texture_a", cell_texture_a)
    init_shader:send("cell_texture_b", cell_texture_b)
    init_shader:send("flux_texture_top_a", flux_texture_top_a)
    init_shader:send("flux_texture_top_b", flux_texture_top_b)
    init_shader:send("flux_texture_center_a", flux_texture_center_a)
    init_shader:send("flux_texture_center_b", flux_texture_center_b)
    init_shader:send("flux_texture_bottom_a", flux_texture_bottom_a)
    init_shader:send("flux_texture_bottom_b", flux_texture_bottom_b)

    init_shader:send("mode", 1) -- init depth
    init_shader:dispatch(texture_w, texture_h)
    init_shader:send("mode", 2) -- init velocities and flux
    init_shader:dispatch(texture_w, texture_h)
end

love.update = function(delta)
    --if not love.keyboard.isDown("space") then return end

    for _ = 1, 1 do
        local cell_texture_in, cell_texture_out
        local flux_texture_top_in, flux_texture_top_out
        local flux_texture_center_in, flux_texture_center_out
        local flux_texture_bottom_in, flux_texture_bottom_out

        if a_or_b == true then
            cell_texture_in = cell_texture_a
            cell_texture_out = cell_texture_b
            flux_texture_top_in = flux_texture_top_a
            flux_texture_top_out = flux_texture_top_b
            flux_texture_center_in = flux_texture_center_a
            flux_texture_center_out = flux_texture_center_b
            flux_texture_bottom_in = flux_texture_bottom_a
            flux_texture_bottom_out = flux_texture_bottom_b
        else
            cell_texture_in = cell_texture_b
            cell_texture_out = cell_texture_a
            flux_texture_top_in = flux_texture_top_b
            flux_texture_top_out = flux_texture_top_a
            flux_texture_center_in = flux_texture_center_b
            flux_texture_center_out = flux_texture_center_a
            flux_texture_bottom_in = flux_texture_bottom_b
            flux_texture_bottom_out = flux_texture_bottom_a
        end

        --step_shader:send("mode", 1) -- update flux
        step_shader:send("cell_texture_in", cell_texture_in)
        step_shader:send("cell_texture_out", cell_texture_out)
        step_shader:dispatch(texture_w, texture_h)

        --[[
        step_shader:send("flux_texture_top_in", flux_texture_top_in)
        step_shader:send("flux_texture_top_out", flux_texture_top_out)
        step_shader:send("flux_texture_center_in", flux_texture_center_in)
        step_shader:send("flux_texture_center_out", flux_texture_center_out)
        step_shader:send("flux_texture_bottom_in", flux_texture_bottom_in)
        step_shader:send("flux_texture_bottom_out", flux_texture_bottom_out)
        step_shader:dispatch(texture_w, texture_h)

        --[[
        step_shader:send("mode", 2) -- update depth and velocities
        step_shader:send("cell_texture_in", cell_texture_in)
        step_shader:send("cell_texture_out", cell_texture_out)
        step_shader:send("flux_texture_top_in", flux_texture_top_out) -- out holds newest state
        step_shader:send("flux_texture_top_out", flux_texture_top_in)
        step_shader:send("flux_texture_center_in", flux_texture_center_out)
        step_shader:send("flux_texture_center_out", flux_texture_center_in)
        step_shader:send("flux_texture_bottom_in", flux_texture_bottom_out)
        step_shader:send("flux_texture_bottom_out", flux_texture_bottom_in)
        step_shader:dispatch(texture_w, texture_h)
        ]]--

        a_or_b = not a_or_b
    end
end

love.resize = function(w, h)
    render_shape = rt.VertexRectangle(0, 0, w, h)
end

love.keypressed = function(which)
    if which == "b" then love.load() end
end

love.draw = function()
    love.graphics.setColor(1, 1, 1, 1)

    render_shader:bind()
    if a_or_b then
        render_shader:send("cell_texture", cell_texture_a)
        render_shader:send("flux_texture_top", flux_texture_top_a)
        render_shader:send("flux_texture_center", flux_texture_center_a)
        render_shader:send("flux_texture_bottom", flux_texture_bottom_a)
    else
        render_shader:send("cell_texture", cell_texture_b)
        render_shader:send("flux_texture_top", flux_texture_top_b)
        render_shader:send("flux_texture_center", flux_texture_center_b)
        render_shader:send("flux_texture_bottom", flux_texture_bottom_b)
    end
    render_shape:draw()
    render_shader:unbind()

    love.graphics.print(love.timer.getFPS(), 0, 0)
end