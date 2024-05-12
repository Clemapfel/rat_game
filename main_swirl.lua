require "include"

swirl = {}
swirl.shader = rt.Shader("lichen/swirl.glsl")
swirl.texture = rt.Texture("assets/love2d.png")
swirl.texture:set_wrap_mode(rt.TextureWrapMode.ZERO)
swirl.shape = rt.VertexRectangle(0, 0, 1, 1)
swirl.elapsed = 0
swirl.direction = true
swirl.active = false

love.load = function()
    love.window.setMode(800, 600, {
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
    if swirl.active then
        if swirl.direction == true then
            swirl.elapsed = swirl.elapsed + delta
        else
            swirl.elapsed = swirl.elapsed - delta
        end
    end
end

love.keypressed = function(which)
    if which == "space" then
        swirl.active = true
        swirl.direction = not swirl.direction
    end
end

love.draw = function()
    love.graphics.clear(0.5, 0.5, 0.5, 1)
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

