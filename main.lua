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
local points =  {
    x, y - y / 2,
    x + w, y,
    x + w + 100, y + h + 20,
    x - 10, y + h - 50,
    x - 10, y + h + 150,
    x + w + 10, y + h + 150
}
--table.insert(points, points[1])
--table.insert(points, points[2])


points = {}
for i = 1, 2, 1 do
    table.insert(points, rt.random.number(50, love.graphics.getWidth() - 50))
    table.insert(points, rt.random.number(50, love.graphics.getHeight() - 50))
    table.insert(points, rt.random.number(50, love.graphics.getWidth() - 50))
    table.insert(points, rt.random.number(50, love.graphics.getHeight() - 50))
end

--[[
points = {x, y,
          x + w, y,
          x + w, y + h,
          x, y + h,
            x, y}
            ]]--

--horizontally_aligned: 90 or -90
--vertically aligned: 180 or 0

local font = rt.settings.font.default[rt.FontStyle.REGULAR]
local str = "<u><o><shake><wave><rainbow>" .. "To_jyäü al balsu bldasiu ba" .. "</shake></wave></rainbow></o></u>"

label = rt.Label(str)
rt.current_scene:set_child(label)

local i = rt.random.seed(os.time(os.date("!*t")))
rt.current_scene.input:signal_connect("pressed", function(_, which)

    if which == rt.InputButton.A then
        points = {}
        for i = 1, 2, 1 do
            table.insert(points, rt.random.number(50, love.graphics.getWidth() - 50))
            table.insert(points, rt.random.number(50, love.graphics.getHeight() - 50))
            table.insert(points, rt.random.number(50, love.graphics.getWidth() - 50))
            table.insert(points, rt.random.number(50, love.graphics.getHeight() - 50))
        end
        shape = rt.VertexRectangleSegments(5, splat(points))

    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.RIGHT then
        label:set_n_visible_characters(label:get_n_visible_characters() + 1)
    elseif which == rt.InputButton.LEFT then
        label:set_n_visible_characters(label:get_n_visible_characters() - 1)
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
    love.graphics.clear(1, 0, 1, 1)
    rt.current_scene:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
end
