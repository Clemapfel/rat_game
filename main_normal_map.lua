require "include"

image = love.graphics.newImage("assets/normal_map_palette.png")
image_x, image_y = 0, 0

love.window.setMode(image:getWidth(), image:getHeight(), {
    resizable = true
})

light_x, light_y, light_z = 0, 0, 0
shader = rt.Shader("common/normal_map_lighting.glsl")

love.load = function()
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.resize = function(screen_w, screen_h)
    local image_w, image_h = image:getDimensions()
    image_x = 0.5 * screen_w - 0.5 * image_w
    image_y = 0.5 * screen_h - 0.5 * image_h
end

love.update = function(delta)

    if love.keyboard.isDown("up") then
        light_z = light_z + 0.05
        dbg(light_z)
    elseif love.keyboard.isDown("down") then
        light_z = light_z - 0.05
        dbg(light_z)
    end

    local mouse_x, mouse_y = love.mouse.getPosition()
    shader:send("light_position", {mouse_x, mouse_y, light_z})
end

love.keypressed = function(_, which)
    if which == "escape" then
        shader:recompile()
        dbg("recompile")
    end
end

love.draw = function()
    shader:bind()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, image_x, image_y)
    shader:unbind()
end