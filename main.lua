require "include"
STATE = rt.GameState()
STATE:initialize_debug_party()

cloth = rt.Cloth(500, 500, 20, 20)
cloth:realize()
local texture = rt.Texture("assets/why.png")
--cloth._mesh:setTexture(texture._native)

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
    cloth:update(delta, 15)
end

love.draw = function()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, rt.graphics.get_width(), rt.graphics.get_height())

    --love.graphics.translate(200, 50)
    cloth:draw()
    --love.graphics.translate(-200, -50)
end

love.resize = function()

end

love.run = function()
    STATE:run()
end