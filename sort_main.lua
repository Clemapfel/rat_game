require "include"

love.window.setMode(800, 600, {
    vsync = 0
})



n_numbers = 14000
shader = rt.ComputeShader("sort_pass.glsl", {
    defines = {
        N_NUMBERS = n_numbers
    }
})

input_buffer = rt.GraphicsBuffer(shader:get_buffer_format("input_buffer"), n_numbers)
output_buffer = rt.GraphicsBuffer(shader:get_buffer_format("output_buffer"), n_numbers)
--count_buffer = rt.GraphicsBuffer(shader:get_buffer_format("global_counts_buffer"), 256)

shader:send("input_buffer", input_buffer._native)
shader:send("output_buffer", output_buffer._native)

do
    local data = {}
    for _ = 1, n_numbers do
        table.insert(data, rt.random.integer(0, 999999))
    end
    input_buffer:replace_data(data)
    output_buffer:replace_data(data)
end

function test_buffer()
    local data = output_buffer:readback_data()
    local sorted = true
    for i = 1, n_numbers - 1 do
        local a = data:getUInt32(((i - 1) + 0) * (32 / 8))
        local b = data:getUInt32(((i - 1) + 1) * (32 / 8))
        if not (a <= b) then
            println(i .. " " .. a .. " " .. b)
            sorted = false
            break
        end
    end

    if sorted then println("sorted") else println("not sorted") end
end

shader:dispatch(1, 1)
test_buffer()

love.update = function(delta)
    shader:dispatch(1, 1)
end

love.draw = function()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(love.timer.getFPS(), 10, 10, POSITIVE_INFINITY)
end


