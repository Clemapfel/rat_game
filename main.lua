require("include")

rt.add_scene("debug")


local audio = rt.Audio("assets/sound/test_soundeffect.wav")
local transform = rt.FourierTransform()
transform:compute_from_audio(audio)

local playback = rt.AudioPlayback(audio)
playback:set_should_loop(true)

local image = transform:as_image()
rt.current_scene:set_child(rt.ImageDisplay(image))

rt.current_scene.input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        local current = playback:get_is_playing()
        if current then
            playback:pause()
        else
            playback:play()
        end
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
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
end
