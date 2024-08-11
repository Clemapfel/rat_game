require "include"
STATE = rt.GameState()
STATE:initialize_debug_party()

dbg(STATE._state)



love.load = function()

end

love.update = function(delta)
end

love.draw = function()
end

love.resize = function()

end

love.run = function()
    STATE:run()
end