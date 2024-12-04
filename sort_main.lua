require "include"



shader = rt.ComputeShader("sort_pass.glsl")

n_numbers = 10000
input_buffer = rt.GraphicsBuffer(shader:get_buffer_format("input_buffer"), n_numbers)
output_buffer = rt.GraphicsBuffer(shader:get_buffer_format("output_buffer"), n_numbers)
count_buffer = rt.GraphicsBuffer(shader:get_buffer_format("global_counts_buffer"), 256)

shader:send("input_buffer", input_buffer)
shader:send("output_buffer", output_buffer)
shader:send("global_counts_buffer", count_buffer)
shader:send("n_numbers", n_numbers)

do
    local data = {}
    for _ = 1, n_numbers do
        table.insert(data, rt.random.integer(0, 9999))
    end
    input_buffer:replace_data(data)
    output_buffer:replace_data(data)
end

function test_buffer()
    local data = output_buffer:readback_data()
    for i = 1, n_numbers - 1 do
        local a = data:getUInt32(((i - 1) + 0) * (32 / 8))
        local b = data:getUInt32(((i - 1) + 1) * (32 / 8))
        print(a, " ", b, " ", "\n")
    end
end

-- main

--test_buffer()

for pass = 0, 3 do
    shader:send("pass", pass)
    shader:dispatch(1, 1)
end

test_buffer()

