require("include")

rt.add_scene("debug")

audio = rt.Audio("assets/sound/test_sound_effect_mono.mp3")
transform = rt.FourierTransform()

clock = rt.Clock()
transform:compute_from_audio(audio, 1024, 128, 1, nil)
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


--[[
ow.Super = meta._new_abstract_type("Super", {
    super_property = 1234
}, meta._abstract_ctor)

ow.Sub = meta._new_type("Sub", ow.Super, {
    sub_property = 4567
}, function()
    println("called")
    return meta.new(ow.Sub)
end)

rt.current_scene = rt.add_scene("debug")
local scene = ow.OverworldScene()
rt.current_scene:set_child(scene)

rt.current_scene.input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
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
end
]]--