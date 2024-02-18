require("include")

local processor = rt.AudioProcessor("test_music_mono.mp3", "assets/sound")

local ft = rt.FourierTransform()

function rt.AudioProcessorTransform(window_size)

end

--- @param data love.ByteData<double>
--- @param offset Number
--- @param window_size Number
function processor:compute()
    local data = self._signal   -- love.ByteData<double*>
    local offset = 2048
    local window_size = self._step_size

    local real_in = ft._alloc_real(window_size)
    local complex_out = ft._alloc_complex(window_size)
    local plan = ft._plan_dft_r2c_1d(
        window_size,
        real_in,
        complex_out,
        ft._plan_mode
    )

    local from = ffi.cast(ft._real_data_t, data:getFFIPointer())
    local to = ffi.cast(ft._real_data_t, real_in)
    ffi.copy(to, from + offset, window_size * ffi.sizeof("double"))

    ft._execute(plan)

    local out = {}

    local complex_data = ffi.cast(ft._complex_data_t, complex_out)
    local half = math.floor(0.5 * window_size)
    for i = 0, window_size / 2 do
        local complex = ffi.cast(ft._complex_t, complex_data[half - i - 1])
        local magnitude = rt.magnitude(complex[0], complex[1])
        table.insert(out, magnitude)
    end

    return out
end

clock = rt.Clock()
processor:compute()
println(clock:get_elapsed())



rt.current_scene = rt.add_scene("debug")
local scene = ow.OverworldScene()
rt.current_scene:set_child(scene)

rt.current_scene.input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        scene._player:set_position(350, 330)
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.DOWN then
    end
end)

-- ##

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
    love.graphics.clear(0.8, 0, 0.8, 1)
    rt.current_scene:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
    processor:update()
end
