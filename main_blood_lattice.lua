require "include"

local texture_w, texture_h = 512, 512
local velocity_texture_top_a, velocity_texture_top_b       -- rgb: top-left, top, top-right
local velocity_texture_center_a, velocity_texture_center_b -- rgb: bottom-left, bottom, bottom-right
local velocity_texture_bottom_a, velocity_texture_bottom_b -- rgb: density, x-velocity, y-velocity
local macroscopic_texture -- r: density, gb: velocity

local relaxation_factor = 0.5
local lattice_size = {texture_w, texture_h}
local a_or_b = true

local init_shader = rt.ComputeShader("main_blood_lattice_init.glsl")
local step_shader = rt.ComputeShader("main_blood_lattice_step.glsl")
local render_shader = rt.Shader("main_blood_lattice_render.glsl")
local render_shape = nil -- rt.VertexRectangle

love.load = function()
    love.window.setMode(texture_w, texture_h)
    local config = {
        format = "rgba32f",
        computewrite = true
    }

    velocity_texture_top_a = love.graphics.newCanvas(texture_w, texture_h, config)
    velocity_texture_top_b = love.graphics.newCanvas(texture_w, texture_h, config)

    velocity_texture_center_a = love.graphics.newCanvas(texture_w, texture_h, config)
    velocity_texture_center_b = love.graphics.newCanvas(texture_w, texture_h, config)

    velocity_texture_bottom_a = love.graphics.newCanvas(texture_w, texture_h, config)
    velocity_texture_bottom_b = love.graphics.newCanvas(texture_w, texture_h, config)

    macroscopic_texture = love.graphics.newCanvas(texture_w, texture_h, config)

    init_shader:send("velocity_texture_top_in", velocity_texture_top_a)
    init_shader:send("velocity_texture_center_in", velocity_texture_center_a)
    init_shader:send("velocity_texture_bottom_in", velocity_texture_bottom_a)
    init_shader:send("lattice_size", lattice_size)

    init_shader:dispatch(texture_w, texture_h)
    love.update(1 / 60)
    love.resize(512, 512)
end

love.update = function(delta)
    local top_in, center_in, bottom_in
    local top_out, center_out, bottom_out
    if a_or_b == true then
        top_in, top_out = velocity_texture_top_a, velocity_texture_top_b
        center_in, center_out = velocity_texture_center_a, velocity_texture_center_b
        bottom_in, bottom_out = velocity_texture_bottom_a, velocity_texture_bottom_b
    else
        top_in, top_out = velocity_texture_top_b, velocity_texture_top_a
        center_in, center_out = velocity_texture_center_b, velocity_texture_center_a
        bottom_in, bottom_out = velocity_texture_bottom_b, velocity_texture_bottom_a
    end

    step_shader:send("delta", delta)
    step_shader:send("velocity_texture_top_in", top_in)
    step_shader:send("velocity_texture_top_out", top_out)

    step_shader:send("velocity_texture_center_in", center_in)
    step_shader:send("velocity_texture_center_out", center_out)

    step_shader:send("velocity_texture_bottom_in", bottom_in)
    step_shader:send("velocity_texture_bottom_out", bottom_out)

    step_shader:send("macroscopic", macroscopic_texture)
    step_shader:dispatch(texture_w, texture_h)

    a_or_b = not a_or_b
end

love.resize = function(w, h)
    render_shape = rt.VertexRectangle(0, 0, w, h)
end

love.draw = function()
    love.graphics.print(love.timer.getFPS(), 0, 0)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(macroscopic_texture)

    --[[
    render_shader:bind()
    render_shader:send("macroscopic", macroscopic_texture)
    render_shape:draw()
    render_shader:unbind()
    ]]--
end