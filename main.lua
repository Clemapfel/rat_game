require "include"

state = rt.GameState()
state:initialize_debug_state()
scene = mn.InventoryScene(state)

option = mn.OptionButton("A", "BBB", "C-")
option:realize()
option:fit_into(100, 100, 200, 50)

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.RIGHT then
        option:move_right()
    elseif which == rt.InputButton.LEFT then
        option:move_left()
    elseif which == rt.InputButton.A then
        background._shader:recompile()
    end
end)

background = bt.Background.POLAR_COORDINATES()
background:realize()

love.load = function()
    if scene ~= nil then
        scene:realize()
        scene:create_from_state(state)
        love.resize()
    end
end

love.update = function(delta)
    if scene ~= nil then
        scene:update(delta)
    end

    option:update(delta)
    background:update(delta)
end

love.draw = function()
    if scene ~= nil then
        --scene:draw()
    end

    option:draw()
    ---background:draw()
end

love.resize = function()
    local x, y, w, h = 0, 0, rt.graphics.get_width(), rt.graphics.get_height()
    if scene ~= nil then
        scene:fit_into(x, y, w, h)
    end

    background:fit_into(x, y, w, h)
end

love.run = function()
    state:run()
end
