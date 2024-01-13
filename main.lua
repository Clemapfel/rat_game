require("include")

rt.add_scene("debug")

audio = rt.Audio("assets/sound/test_music.mp3")
transform = rt.FourierTransform()

clock = rt.Clock()
transform:compute_from_audio(audio, 256, 15, 1, 1024 * 200)
println("transform: ", clock:restart():as_seconds())

image = transform:as_image()
println("image: ", clock:restart():as_seconds())
image:save_to_file("test_music_fourier_transfrom.png")
println("saved image")

display = rt.ImageDisplay(image)
rt.current_scene:set_child(display)

playback = rt.AudioPlayback(audio)
playhead = rt.Line(0, 0, 0, love.graphics.getHeight())
playhead:set_color(rt.Palette.RED)
playhead:set_line_width(5)

rt.current_scene.input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        playback:play()
    end
end)

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
    playhead:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)

    local x = playback:get_position():as_seconds() / audio:get_duration():as_seconds() * love.graphics.getWidth()
    println(x)
    playhead:resize(x, 0, x, love.graphics.getHeight())
end
