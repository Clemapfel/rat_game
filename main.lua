require("include")

rt.add_scene("debug")
local log = bt.BattleLog()
log:set_margin_horizontal(100)
log:set_margin_top(20)
log:set_vertical_alignment(rt.Alignment.START)
log:set_expand_vertically(false)

log._frame:set_minimum_size(0, 250)
rt.current_scene:set_child(log)

local x, y, w, h = 100, 100, 400, 300
local thickness = 20
local points =  {x, y - y / 2, x + w, y, x + w + 100, y + h + 20, x, y + h - 50}
table.insert(points, points[1])
table.insert(points, points[2])

shape = rt.VertexLine(thickness, splat(points))

--[[
local font = rt.settings.font.default[rt.FontStyle.REGULAR]
local str = "<s><u><o><wave><shake>" .. "To_jyäü al balsu bldasiu ba" .. "</shake></wave></o></u></s>"

label = rt.Label(str)
rt.current_scene:set_child(label)
]]--

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
    love.graphics.clear()
    --rt.current_scene:draw()
    shape:draw()

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.setPointSize(3)
    love.graphics.points(splat(points))
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
end
