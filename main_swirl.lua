require "include"

swirl = {}
swirl.shader = rt.Shader("lichen/swirl.glsl")
swirl.texture = rt.Texture("lichen/rhombus.jpg")
swirl.shape = rt.VertexRectangle(0, 0, 1, 1)
swirl.elapsed = 0

love.load = function()
    love.window.setMode(600, 600, {
        vsync = -1, -- adaptive vsync, may tear but tries to stay as close to 60hz as possible
        msaa = 8,
        stencil = true,
        resizable = true,
        borderless = false
    })
    love.window.setTitle("rat_game: lichen")
    love.filesystem.setIdentity("rat_game")
    love.resize()

    swirl.shape:set_texture(swirl.texture)
end

love.update = function(delta)
    swirl.elapsed = swirl.elapsed + delta
end

love.draw = function()
    swirl.shader:bind()
    swirl.shader:send("elapsed", swirl.elapsed)
    --swirl.shader:send("texture_size", {swirl.texture:get_size()})
    swirl.shape:draw()
    swirl.shader:unbind()
end

love.resize = function()
    local w, h = rt.graphics.get_width(), rt.graphics.get_height()
    swirl.shape:set_vertex_position(1, 0, 0)
    swirl.shape:set_vertex_position(2, w, 0)
    swirl.shape:set_vertex_position(3, w, h)
    swirl.shape:set_vertex_position(4, 0, h)
end

