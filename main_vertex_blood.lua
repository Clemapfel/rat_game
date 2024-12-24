require "include"

local data = love.image.newImageData("assets/marching_squares_test_image.png")
local w, h = data:getDimensions()
local new_data = love.image.newImageData(w, h, "r32f")
for x = 1, w do
    for y = 1, h do
        local r, g, b, a = data:getPixel(x - 1, y - 1)
        new_data:setPixel(x - 1, y - 1, a, a, a, a)
    end
end

local texture = meta.new(rt.Texture, {
    _native =  love.graphics.newImage(new_data, {computewrite = true})
})

local vertex_gen_shader = rt.ComputeShader("main_vertex_blood_vertex_gen.glsl")
local render_shader = rt.Shader("main_vertex_blood_threshold.glsl")
local vertices = {}

local threshold = 1 - 0.00

function compute()
    local texture_w, texture_h = texture:get_size()
    vertex_gen_shader:send("image", texture._native)
    vertex_gen_shader:send("image_width", texture_w)
    vertex_gen_shader:send("image_height", texture_h)
    vertex_gen_shader:send("threshold", threshold)

    local max_n_vertices = 2 * (texture_w - 1) * (texture_h - 1)

    local buffer_format = {
        {format = "floatvec4"}
    }

    local segments_buffer = rt.GraphicsBuffer(
        buffer_format,
        max_n_vertices
    )

    local is_valid_buffer = rt.GraphicsBuffer(
        vertex_gen_shader:get_buffer_format("is_valid_buffer"),
        max_n_vertices
    )

    local is_valid_data = table.rep(0, max_n_vertices)
    is_valid_buffer:replace_data(is_valid_data)

    vertex_gen_shader:send("segments_buffer", segments_buffer._native)
    vertex_gen_shader:send("is_valid_buffer", is_valid_buffer._native)

    vertex_gen_shader:dispatch(texture_w / 32, texture_h / 32)

    local vertex_data = segments_buffer:readback_data()
    local is_valid_data = is_valid_buffer:readback_data()

    local n_valid = 0
    vertices = {}
    local _byte = 4
    local segment_i = 1
    for i = 1, max_n_vertices do
        if is_valid_data:getUInt32((i - 1) * _byte) ~= 0 then
            for x in range(
                vertex_data:getFloat((segment_i - 1 + 0) * _byte),
                vertex_data:getFloat((segment_i - 1 + 1) * _byte),
                vertex_data:getFloat((segment_i - 1 + 2) * _byte),
                vertex_data:getFloat((segment_i - 1 + 3) * _byte)
            ) do
                table.insert(vertices, x)
            end
            n_valid = n_valid + 1
        end

        segment_i = segment_i + 4
    end

    dbg(threshold, n_valid)
end

compute = function()  end

love.load = function()
    local texture_w, texture_h = texture:get_size()
    love.window.setMode(texture_w, texture_h, {
        msaa = 0,
        vsync = 0
    })

    compute()
end

love.keypressed = function(which)
    if which == "up" then
        threshold = threshold - 0.005
        compute()
    elseif which == "down" then
        threshold = threshold + 0.005
        compute()
    end
end

love.update = function()
    if love.keyboard.isDown("space") then
        threshold = threshold - 0.005
        compute()
    end
end

love.draw = function()
    render_shader:bind()
    render_shader:send("threshold", threshold)
    texture:draw()
    render_shader:unbind()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.points(vertices)
end