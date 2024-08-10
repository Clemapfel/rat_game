require "include"
require "common.game_state"
STATE = rt.GameState()

label = rt.Label("<o><mono><rainbow>TEST TEST</mono></o></rainbow>")
label:realize()
label:fit_into(50, 50)

love.load = function()

end

love.update = function(delta)
    label:update(delta)
end

love.draw = function()
    label:draw()
end

love.resize = function()

end