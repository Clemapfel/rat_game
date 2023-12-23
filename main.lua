require "include"

rt.add_scene("debug")

input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)

    local speed = 0.1
    if which == rt.InputButton.A then
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.UP then
        rt.settings.battle_background.dampening = rt.settings.battle_background.dampening + 0.1
        rt.settings.battle_background.dampening = clamp(rt.settings.battle_background.dampening, 0, 1)
    elseif which == rt.InputButton.DOWN then
        rt.settings.battle_background.dampening = rt.settings.battle_background.dampening - 0.1
        rt.settings.battle_background.dampening = clamp(rt.settings.battle_background.dampening, 0, 1)
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    end

    if which == rt.InputButton.A then
    end
end)


mapping = {}
mapping[rt.InputButton.A] = "Press A"
mapping[rt.InputButton.B] = "Press B"
mapping[rt.InputButton.X] = "Press X"
mapping[rt.InputButton.Y] = "Press Y"
mapping[rt.InputButton.L] = "Press L"
mapping[rt.InputButton.R] = "Press R"
mapping[rt.InputButton.START] = "Press Plus"
mapping[rt.InputButton.SELECT] = "Press Minus"
mapping[rt.InputButton.UP] = "Press Up"
mapping[rt.InputButton.DOWN] = "Press Down"
mapping[rt.InputButton.LEFT] = "Press Left"
mapping[rt.InputButton.RIGHT] = "Press Right"

indicator = rt.KeymapIndicator(mapping)
rt.current_scene:set_child(indicator)

function love.load()
    rt.current_scene:realize()
end

local mesh = love.graphics.newMesh(rt.VertexFormat, {
    {0, 0, 0,  0, 0, 1, 1, 1, 1}
}, "points")

function love.draw()

    love.graphics.clear(1, 0, 1, 1)
    rt.current_scene:draw()
    
    -- scene rendering
    rt.current_scene:draw()
end

function love.update()
    rt.current_scene:update(love.timer.getDelta())
end