require "include"

rt.add_scene("debug")

local equipment = bt.Equipment("TEST_EQUIPMENT")
local tooltip = bt.EquipmentTooltip(equipment)
rt.current_scene:set_child(tooltip)

draw_2d = true
input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)
    local speed = 0.1
    if which == rt.InputButton.UP then
        rt.Renderer:move_camera(0, speed, 0)
    elseif which == rt.InputButton.DOWN then
        rt.Renderer:move_camera(0, -speed, 0)
    elseif which == rt.InputButton.RIGHT then
        rt.Renderer:move_camera(speed, 0, 0)
    elseif which == rt.InputButton.LEFT then
        rt.Renderer:move_camera(-speed, 0, 0)
    elseif which == rt.InputButton.R then
        rt.Renderer:move_camera(0, 0, speed)
    elseif which == rt.InputButton.L then
        rt.Renderer:move_camera(0, 0, -speed)
    elseif which == rt.InputButton.X then
        draw_2d = not draw_2d
    end

    if which == rt.InputButton.A then
        rt.Renderer:reset_camera()
    end
end)

function love.load()
    rt.current_scene:realize()
end

function love.draw()
    -- 3d rendering
    rt.Renderer:draw_2d(function()
        rt.current_scene:draw()
    end)
    rt.Renderer:draw_3d(function()
        --mesh:draw()
    end)
    rt.Renderer:draw()

    -- scene rendering
    --rt.current_scene:draw()
end