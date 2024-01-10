require("include")

rt.add_scene("debug")

audio = rt.Audio("assets/sound/test_sound_effect_mono.mp3")
transform = rt.FourierTransform()

clock = rt.Clock()
transform:compute_from_audio(audio, 256, 1, 1, nil)
println("transform: ", clock:restart():as_seconds())

image = transform:as_image()
println("image: ", clock:restart():as_seconds())

display = rt.ImageDisplay(image)
rt.current_scene:set_child(display)

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
