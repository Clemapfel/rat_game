require "include"
STATE = rt.GameState()
STATE:initialize_debug_party()

for e in values(STATE:list_entities()) do
    dbg(e:get_id())
end


love.load = function()
    gradient = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
    gradient:set_vertex_color(1, rt.RGBA(1, 1, 1, 1))
    gradient:set_vertex_color(2, rt.RGBA(0, 0, 0, 1))
    gradient:set_vertex_color(3, rt.RGBA(1, 1, 1, 1))
    gradient:set_vertex_color(4, rt.RGBA(0, 0, 0, 1))
end

love.update = function(delta)
end

love.draw = function()
    gradient:draw()

    love.graphics.setColor(0, 1, 0, 1)
    local x, y = love.mouse.getPosition()
    love.graphics.circle("fill", x, y, 150, 150)

   -- love.graphics.setBlendState("add", "max", "srcalpha", "srcalpha", "oneminussrcalpha", "oneminussrcalpha")
    rt.graphics.set_blend_mode(rt.BlendMode.NORMAL, rt.BlendMode.MAX)
    love.graphics.setColor(1, 0, 1, 0.25)
    love.graphics.circle("fill", 300, 300, 200, 200)
    love.graphics.setColor(0, 1, 1, 0.33)
    love.graphics.circle("fill", 300 + 100, 300, 200, 200)
end

love.resize = function()

end

love.run = function()
    STATE:run()
end