require "include"
STATE = rt.GameState()
STATE:initialize_debug_state()

local template = STATE:list_templates()[1]

for move in values(template:list_move_slots(template:list_entities()[1])) do
    dbg(move:get_id())
end


love.load = function()

end

love.update = function()
end

love.draw = function()
end

love.resize = function()

end

love.run = function()
    STATE:run()
end