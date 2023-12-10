require "include"

rt.add_scene("debug")

entity = bt.Entity("TEST_ENTITY")

move = bt.Action("TEST_MOVE")
consumable = bt.Action("TEST_CONSUMABLE")
intrinsic = bt.Action("TEST_INTRINSIC")

for _, action in pairs({move, consumable, intrinsic}) do
    entity:add_action(action)
end

selection_menu = bt.ActionSelectionMenu(entity)
rt.current_scene:set_child(rt.Label("TEST 0123456789"))

input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)

    local speed = 0.1
    if which == rt.InputButton.A then
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.DOWN then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    end

    if which == rt.InputButton.A then
    end
end)

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
    --rt.current_scene:draw()

    love.graphics.draw(mesh)
end