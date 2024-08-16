require "include"

state = rt.GameState()
state:initialize_debug_state()
scene = mn.InventoryScene(state)

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
end

love.draw = function()
    if scene ~= nil then
        scene:draw()
    end
end

love.resize = function()
    local x, y, w, h = 0, 0, rt.graphics.get_width(), rt.graphics.get_height()
    if scene ~= nil then
        scene:fit_into(x, y, w, h)
    end
end

love.run = function()
    state:run()
end
