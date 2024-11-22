require "include"

do
    local input = {}
    for i = 1, 100 do
        table.insert(input, math.round(love.math.random(0, 2^8)))
    end

    local bits_per_step = 8
    local n_buckets = 2^(bits_per_step)
    local counts, offsets = {}, {}
    local output = {}

    for pass = 0, (32 / bits_per_step) - 1 do
        for i = 1, n_buckets do
            counts[i] = 0
            offsets[i] = 0
        end

        local bitmask = bit.lshift(0xFF, pass * bits_per_step)

        -- count occurences
        for x in values(input) do
            local mask = bit.rshift(bit.band(x, bitmask), pass * bits_per_step)
            counts[mask + 1] = counts[mask + 1] + 1
        end

        -- prefix sum
        local sum = 0
        for i = 1, n_buckets do
            offsets[i] = sum
            sum = sum + counts[i]
        end

        -- reorder elements
        for x in values(input) do
            local mask = bit.rshift(bit.band(x, bitmask), pass * bits_per_step)
            output[offsets[mask + 1] + 1] = x
            offsets[mask + 1] = offsets[mask + 1] + 1
        end

        -- copy output back to input for the next pass
        for i = 1, #input do
            input[i] = output[i]
        end
    end
end

to_sort_buffer = nil
to_sort_swap_buffer = nil
shared_counts_buffer = nil
shared_offsets_buffer = nil

sort_shader = love.graphics.newComputeShader("common/blood_sort_temp.glsl")
n_numbers = 256^2
n_bits_per_step = 8

n_threads_x = 1
n_threads_y = 1

love.load = function()
    local buffer_usage = {
        usage = "dynamic",
        shaderstorage = true
    }

    local to_sort_buffer_format = sort_shader:getBufferFormat("to_sort_buffer")
    to_sort_buffer = love.graphics.newBuffer(to_sort_buffer_format, n_numbers, buffer_usage)

    local to_sort_swap_buffer_format = sort_shader:getBufferFormat("to_sort_swap_buffer")
    to_sort_swap_buffer = love.graphics.newBuffer(to_sort_swap_buffer_format, n_numbers, buffer_usage)

    local shared_counts_buffer_format = sort_shader:getBufferFormat("shared_counts_buffer")
    shared_counts_buffer = love.graphics.newBuffer(shared_counts_buffer_format, 2^n_bits_per_step, buffer_usage)

    local shared_offsets_buffer_format = sort_shader:getBufferFormat("shared_offsets_buffer")
    shared_offsets_buffer = love.graphics.newBuffer(shared_offsets_buffer_format, 2^n_bits_per_step, buffer_usage)

    do
        local data = {}
        for i = 1, n_numbers do
            table.insert(data, {
                i,
                rt.random.integer(0, 999)
            })
        end
        to_sort_buffer:setArrayData(data)
        to_sort_swap_buffer:setArrayData(data)

        local data = {}
        for i = 1, 2^n_bits_per_step do
            data[i] = 0
        end
        shared_counts_buffer:setArrayData(data)
        shared_offsets_buffer:setArrayData(data)
    end

    sort_shader:send("to_sort_buffer", to_sort_buffer)
    sort_shader:send("to_sort_swap_buffer", to_sort_swap_buffer)
    sort_shader:send("shared_counts_buffer", shared_counts_buffer)
    sort_shader:send("shared_offsets_buffer", shared_offsets_buffer)

    sort_shader:send("n_threads_x", n_threads_x)
    sort_shader:send("n_threads_y", n_threads_y)
    sort_shader:send("n_numbers", n_numbers)
    sort_shader:send("n_bits_per_step", n_bits_per_step)

    local function print_buffer()
        local byte_offset = 4
        local data = love.graphics.readbackBuffer(to_sort_buffer);
        for i = 1, 256, 2 do
            local index = data:getUInt32((i - 1) * byte_offset)
            local hash = data:getUInt32((i - 1 + 1) * byte_offset)
            println(index, " ", hash)
        end
    end

    function get_index_range(thread_x, thread_y)
        local linear_index = thread_y * n_threads_x + thread_x
        local n_per_thread = n_numbers / (n_threads_x * n_threads_y)
        local start = linear_index * n_per_thread
        local finish = clamp(start + n_per_thread, 0, n_numbers)
        dbg(thread_x, thread_y, math.round(start), math.round(finish))

        for x = 0, n_threads_x - 1 do
            for y = 0, n_threads_y - 1 do
                get_index_range(x, y)
            end
        end
    end

    --print_buffer()
    love.graphics.dispatchThreadgroups(sort_shader, n_threads_x, n_threads_y)
    print_buffer()

    exit()
end


--[[
--[[
sources
    https://developer.nvidia.com/gpugems/gpugems3/part-v-physics-simulation/chapter-32-broad-phase-collision-detection-cuda
    https://gpuopen.com/download/publications/Introduction_to_GPU_Radix_Sort.pdf

    for each particle, create cell hash as particle_x | particle_y, 32-bit uint
    create buffer valid_cells with n_cells many entires, initialized as false
    write particle id unordered to buffer, during scan set valid_cells at cell hash to true
    radix-sort particle id buffer by cell hash
    create buffer cell hash to list of particles
    iterate through sorted buffer, writing to hash-to-particle buffer, anytime the hash transitions, new cell is seen

    hash-to-particle-buffer layout:
        list of all particle ids, in order of cell
        second buffer with cell-hash to offset

do
    local input = {}
    for i = 1, 100 do
        table.insert(input, math.round(love.math.random(0, 2^8)))
    end

    local bits_per_step = 8
    local n_buckets = 2^(bits_per_step)
    local counts, offsets = {}, {}
    local output = {}

    for pass = 0, (32 / bits_per_step) - 1 do
        for i = 1, n_buckets do
            counts[i] = 0
            offsets[i] = 0
        end

        local bitmask = bit.lshift(0xFF, pass * bits_per_step)

        -- count occurences
        for x in values(input) do
            local mask = bit.rshift(bit.band(x, bitmask), pass * bits_per_step)
            counts[mask + 1] = counts[mask + 1] + 1
        end

        -- prefix sum
        local sum = 0
        for i = 1, n_buckets do
            offsets[i] = sum
            sum = sum + counts[i]
        end

        -- reorder elements
        for x in values(input) do
            local mask = bit.rshift(bit.band(x, bitmask), pass * bits_per_step)
            output[offsets[mask + 1] + 1] = x
            offsets[mask + 1] = offsets[mask + 1] + 1
        end

        -- copy output back to input for the next pass
        for i = 1, #input do
            input[i] = output[i]
        end
    end
end

-- config

local n_particles = 100 * 1000
local particle_radius = 10
local particle_n_outer_vertices = 3
local particle_color = rt.Palette.RED

-- globals

local mesh -- love.Mesh
local render_shader = love.graphics.newShader("common/blood_render.glsl")
local velocity_step_shader = love.graphics.newComputeShader("common/blood_velocity_step.glsl")
local spatial_hash_shader = love.graphics.newComputeShader("common/blood_spatial_hash_step.glsl")

local particle_buffer = nil -- love.GraphicsBuffer
local cell_occupation_buffer = nil
local cell_occupation_mapping_buffer = nil
local cell_is_valid_buffer = nil

local elapsed = 0
local color_r, color_g, color_b, color_a = rt.color_unpack(rt.rgba_to_hsva(particle_color)) -- sic, encode hsva by using rgba

local thread_group_stride = love.graphics.getSystemLimits()["threadgroupsx"] / 8 -- arrange dispatch as matrix to get above group limit
local cell_invalid_hash = 0xFFFFFFFF

local cell_radius = particle_radius * 2;
local screen_w, screen_h = love.graphics.getDimensions()
local cell_n_rows = screen_h / cell_radius
local cell_n_columns = screen_w / cell_radius

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
        local offset = 2 * math.pi * 0.25
        for angle = 0, 2 * math.pi, step do
            table.insert(vertices, {
                center_x + math.cos(angle - offset) * particle_radius,
                center_y + math.sin(angle - offset) * particle_radius,
                1, 1, 1, 1
            })
        end

        mesh = love.graphics.newMesh(mesh_format, vertices, "fan", "static")
    end

    do -- init graphics buffers
        local buffer_usage = {
            usage = "dynamic",
            shaderstorage = true
        }

        local particle_buffer_format = spatial_hash_shader:getBufferFormat("particle_buffer")
        particle_buffer = love.graphics.newBuffer(particle_buffer_format, n_particles, buffer_usage)

        do -- init particles
            local data = {}
            for i = 1, n_particles do
                local position_x, position_y = love.math.random(0, love.graphics.getWidth()), love.math.random(0, love.graphics.getHeight())
                table.insert(data, {
                    position_x, position_y, -- current_position
                    position_x, position_y, -- previous_position
                    love.math.random(0, 1) * particle_radius, -- radius
                    love.math.random(0, 2 * math.pi), -- angle
                    love.math.random(0.25, 1), -- color
                })
            end
            particle_buffer:setArrayData(data)
        end

        local cell_is_valid_buffer_format = spatial_hash_shader:getBufferFormat("cell_is_valid_buffer")
        cell_is_valid_buffer = love.graphics.newBuffer(
            cell_is_valid_buffer_format,
            cell_n_rows * cell_n_columns,
            buffer_usage
        )

        local cell_occupation_mapping_buffer_format = spatial_hash_shader:getBufferFormat("cell_occupation_mapping_buffer")
        cell_occupation_mapping_buffer = love.graphics.newBuffer(
            cell_occupation_mapping_buffer_format,
            cell_n_rows * cell_n_columns,
            buffer_usage
        )

        local cell_occupation_buffer_format = spatial_hash_shader:getBufferformat("cell_occupations_buffer")
        cell_occupation_buffer = love.graphics.newBuffer(
            cell_occupation_buffer_format,
            n_particles,
            buffer_usage
        )
    end
end

do
    local _shader_try_send = function(shader, name, item)
        if shader:hasUniform(name) then
            shader:send(name, item)
        end
    end

    love.update = function(delta)
        if not love.keyboard.isDown("space") then
            elapsed = elapsed + delta

            local w, h = love.graphics.getDimensions()
            _shader_try_send(velocity_step_shader, "thread_group_stride", thread_group_stride)
            _shader_try_send(velocity_step_shader, "delta", delta)
            _shader_try_send(velocity_step_shader, "elapsed", elapsed)
            _shader_try_send(velocity_step_shader, "screen_size", {w, h})
            _shader_try_send(velocity_step_shader, "n_particles", n_particles)
            _shader_try_send(velocity_step_shader, "particle_buffer", particle_buffer)
            _shader_try_send(velocity_step_shader, "center_of_gravity", {w / 2, h / 2})
            love.graphics.dispatchThreadgroups(velocity_step_shader,
                thread_group_stride,
                math.ceil(n_particles / thread_group_stride)
            )
        end
    end
end

local clear_color = rt.Palette.GRAY_6
love.draw = function()
    love.graphics.clear(rt.color_unpack(clear_color))

    local scale = 2
    local w, h = love.graphics.getDimensions()
    love.graphics.translate(0.5 * w, 0.5 * h)
    love.graphics.scale(1 / scale, 1 / scale)
    love.graphics.translate(-0.5 * w, -0.5 * h)

    love.graphics.setLineStyle("smooth")
    render_shader:send("particle_buffer", particle_buffer)
    render_shader:send("radius", particle_radius)
    love.graphics.setShader(render_shader)
    love.graphics.setColor(color_r, color_g, color_b, 1)
    love.graphics.drawInstanced(mesh, n_particles)
    love.graphics.setShader()

    love.graphics.origin()
    local margin = 5
    local label = love.timer.getFPS() .. " | " .. n_particles .. " particles"
    love.graphics.setColor(1, 1, 1, 0.75)
    love.graphics.print(label, margin, math.floor(0.5 * margin))
end
]]--