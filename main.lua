require("include")

rt.add_scene("debug")
local log = bt.BattleLog()
log:set_margin_horizontal(100)
log:set_margin_top(20)
log:set_vertical_alignment(rt.Alignment.START)
log:set_expand_vertically(false)

log._frame:set_minimum_size(0, 250)
rt.current_scene:set_child(log)

local font = rt.settings.font.default[rt.FontStyle.REGULAR]
local str = "<s><u><o><wave><shake>" .. "To_jyäü al balsu bldasiu ba" .. "</shake></wave></o></u></s>"

label = rt.Label(str)
rt.current_scene:set_child(label)

rt.current_scene.input:signal_connect("pressed", function(_, which)

    if which == rt.InputButton.A then
        label:set_n_visible_characters(10000)
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
    love.graphics.clear(0.75, 0, 0.75, 1)
    --rt.current_scene:draw()

    label:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
end
