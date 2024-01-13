require("include")

rt.add_scene("debug")
local log = bt.BattleLog()
log:set_margin_horizontal(100)
log:set_margin_top(20)
log:set_vertical_alignment(rt.Alignment.START)
log:set_expand_vertically(false)
log:set_expand_horizontally(false)

log._frame:set_minimum_size(500, 500)
rt.current_scene:set_child(log)

rt.current_scene.input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.DOWN then
    elseif which == rt.InputButton.LEFT then
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
