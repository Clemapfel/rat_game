require("include")

local processor = rt.AudioProcessor("test_music.mp3", "assets/sound")

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
