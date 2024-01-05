require("include")

rt.add_scene("debug")

local entities = rt.List()
local state = {}
for i = 1, 6 + 4 do
    local entity = bt._generate_debug_entity()
    entities:push_back(entity)
    state[i] = entity
end

order = bt.OrderQueue()
order:set_state(state)
rt.current_scene:set_child(order)

log = bt.BattleLog()
log:set_margin_top(rt.settings.margin_unit * 2)
log:set_margin_horizontal(200)
log:set_margin_bottom(200)

rt.current_scene:set_child(log)

local wireframe = false;
input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)

    local speed = 0.1
    if which == rt.InputButton.A then
        local str = {}
        for i = 1, rt.random.integer(4) do
            table.insert(str, rt.random.string(rt.random.integer(4, 7)))
            table.insert(str, " ")
        end
        log:push_back("<wave>" .. string.rep("T#", #str)  .. "</wave>")
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
    rt.current_scene:update(love.timer.getDelta())
end
