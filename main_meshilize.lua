require "include"

image = love.image.newImageData("assets/sprites/battle/consumables.png")
texture = love.graphics.newTexture(image)
texture:setFilter("nearest")

input = rt.InputController()

scale_x, scale_y = 5, 5
love.draw = function()
    love.graphics.push()
    local w, h = texture:getWidth(), texture:getHeight()
    love.graphics.translate(-0.5 * w * scale_x, -0.5 * h * scale_x)
    love.graphics.scale(scale_x, scale_y)
    love.graphics.translate(0.5 * rt.graphics.get_width() / scale_x, 0.5 * rt.graphics.get_height() / scale_y)
    love.graphics.draw(texture)
    love.graphics.pop()

    love.graphics.print("x: " .. scale_x .. " | y: " .. scale_y, 10, 10)
end

input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        scale_x = math.round(scale_x)
        scale_y = math.round(scale_y)
    end
end)

love.update = function(dt)
    local scale_speed = 1
    if input:is_down(rt.InputButton.UP) then
        scale_x = scale_x * (1 + dt) * scale_speed
        scale_y = scale_y * (1 + dt) * scale_speed
    end

    if input:is_down(rt.InputButton.DOWN) then
        scale_x = scale_x / ((1 + dt) * scale_speed)
        scale_y = scale_y / ((1 + dt) * scale_speed)
    end
end


love.resize = function()
    local w, h = image:getWidth(), image:getHeight()
    scale_x = love.graphics.getWidth() / (w / 2) / 2
    scale_y = love.graphics.getHeight() / (w / 2) / 2
    scale_y = scale_y * (love.graphics.getWidth() / love.graphics.getHeight())
    dbg(scale_x)
end

love.load = function()
    love.window.setMode(1600, 900, {
        vsync = -1, -- adaptive vsync, may tear but tries to stay as close to 60hz as possible
        msaa = 0,
        stencil = true,
        resizable = true,
        borderless = false
    })
    love.resize()
end