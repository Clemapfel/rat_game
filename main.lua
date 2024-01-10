require("include")

rt.add_scene("debug")

local ffi = require "ffi"
local fftw = ffi.load("/usr/lib64/libfftw3f.so")
local fftw_cdef = love.filesystem.read("submodules/fftw/cdef.c")
ffi.cdef(fftw_cdef)

local size = 256

local input = fftw.fftwf_alloc_real(size)
local output = fftw.fftwf_alloc_complex(size)
local plan = fftw.fftwf_plan_dft_r2c_1d(size, input, output, 64)

local input_ptr = ffi.cast("float*", input)
for i = 1, size do
    input_ptr[i] = rt.random.number(-1, 1)
end

fftw.fftwf_execute(plan)

local output_ptr = ffi.cast("float*", output)
for i = 1, size do
    local complex = ffi.cast("float*", output_ptr[i])
    println(complex[0], " ", complex[1])
end

-- ######################

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:run()
end

love.draw = function()
    love.graphics.clear(1, 0, 1, 1)
    rt.current_scene:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
end
