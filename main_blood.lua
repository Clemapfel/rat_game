require "include"

-- config

local n_particles = 1 * 1000
local particle_radius = 10
local particle_n_outer_vertices = 16

-- globals

local mesh -- love.Mesh
local color_r, color_g, color_b, color_a = rt.color_unpack(rt.rgba_to_hsva(rt.Palette.RED)) -- sic, encode hsva by using rgba
local render_shader = love.graphics.newShader("common/blood_render.glsl")
local particle_buffer = nil -- love.GraphicsBuffer

love.load = function()
    love.window.setMode(800, 600, {
        msaa = 8
    })

    do -- init circle mesh
        local mesh_format = {
            {name = "VertexPosition", format = "floatvec2"},
            {name = "VertexColor", format = "floatvec4"},
        }

        local center_x, center_y = 0, 0

        local vertices = {}
        local step = 2 * math.pi / particle_n_outer_vertices
        for angle = 0, 2 * math.pi, step do
            table.insert(vertices, {
                center_x + math.cos(angle) * particle_radius,
                center_y + math.sin(angle) * particle_radius,
                1, 1, 1, 1
            })
        end

        mesh = love.graphics.newMesh(mesh_format, vertices, "fan", "static")
    end

    do -- init graphics buffers
        local buffer_format = {
            {name = "current_position", format = "floatvec2"},
            {name = "last_position", format = "floatvec2"},
            {name = "radius", format = "float"},
            {name = "color", format = "float"}
        }

        local buffer_usage = {
            usage = "dynamic",
            shaderstorage = true
        }

        particle_buffer = love.graphics.newBuffer(buffer_format, n_particles, buffer_usage)
        local data = {}
        for i = 1, n_particles do
            local position_x, position_y = love.math.random(0, love.graphics.getWidth()), love.math.random(0, love.graphics.getHeight())
            table.insert(data, {
                position_x, position_y,
                position_x, position_y,
                love.math.random(0, 1) * particle_radius,
                love.math.random(0.25, 1)
            })
        end
        particle_buffer:setArrayData(data)
    end
end

love.update = function(delta)

end

love.draw = function()
    local scale = 2
    local w, h = love.graphics.getDimensions()
    love.graphics.translate(0.5 * w, 0.5 * h)
    love.graphics.scale(1 / scale, 1 / scale)
    love.graphics.translate(-0.5 * w, -0.5 * h)

    love.graphics.setLineStyle("smooth")
    render_shader:send("particle_buffer", particle_buffer)
    love.graphics.setShader(render_shader)
    love.graphics.setColor(color_r, color_g, color_b, 1)
    love.graphics.drawInstanced(mesh, n_particles)
    love.graphics.setShader()

    love.graphics.origin()
    local margin = 5
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.print(love.timer.getFPS(), margin, math.floor(0.5 * margin))
end