

require "include"

local texture
do
    local image_in = love.image.newImageData("assets/marching_squares_test_image.png")
    local image_w, image_h = image_in:getDimensions()
    local image_out = love.image.newImageData(image_w, image_h, "r32f")
    for x = 1, image_w do
        for y = 1, image_h do
            local r, g, b, a = image_in:getPixel(x - 1, y - 1)
            image_out:setPixel(x - 1, y - 1, a, a, a, a)
        end
    end

    texture = meta.new(rt.Texture, {
        _native =  love.graphics.newImage(image_out, {computewrite = true})
    })
end

local vertex_gen_shader = rt.ComputeShader("main_vertex_blood_vertex_gen.glsl")
local render_shader = rt.Shader("main_vertex_blood_threshold.glsl")
local vertices = {}

local threshold = 0.9

love.load = function()
    local texture_w, texture_h = texture:get_size()
    love.window.setMode(texture_w, texture_h, {
        msaa = 0,
        vsync = 0
    })

    vertex_gen_shader:send("image", texture._native)
    vertex_gen_shader:send("image_width", texture_w)
    vertex_gen_shader:send("image_height", texture_h)
    vertex_gen_shader:send("threshold", threshold)

    local max_n_vertices = 2 * (texture_w - 1) * (texture_h - 1)

    local buffer_format = {
        {format = "floatvec4"}
    }

    dbg(vertex_gen_shader._native:getBufferFormat("segments_buffer"))

    local segments_buffer = love.graphics.newBuffer(
        vertex_gen_shader._native:getBufferFormat("segments_buffer"),
        max_n_vertices, {
            shaderstorage = true
        }
    )

    --[[
    local vertex_invalid_buffer = rt.GraphicsBuffer(
        vertex_gen_shader:get_buffer_format("vertex_invalid_buffer"),
        max_n_vertices
    )
    ]]--

    vertex_gen_shader:send("segments_buffer", segments_buffer)
    --vertex_gen_shader:send("vertex_invalid_buffer", vertex_invalid_buffer._native)

    vertex_gen_shader:dispatch(texture_w, texture_h)

    local vertex_data = segments_buffer:readback_data()
    --local is_valid_data = vertex_invalid_buffer:readback_data()

    vertices = {}
    local _byte = 4
    local segment_i = 1
    for i = 1, max_n_vertices do
        --local is_invalid = is_valid_data:getUInt32((i - 1) * _byte)
        --if is_invalid ~= 1 then
            for x in range(
                vertex_data:getFloat((i - 1 + 0) * _byte),
                vertex_data:getFloat((i - 1 + 1) * _byte),
                vertex_data:getFloat((i - 1 + 2) * _byte),
                vertex_data:getFloat((i - 1 + 3) * _byte)
            ) do
                table.insert(vertices, x)
            end
        --end

        segment_i = segment_i + 4
    end
end

love.draw = function()
    render_shader:bind()
    render_shader:send("threshold", threshold)
    texture:draw()
    render_shader:unbind()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.line(vertices)
end