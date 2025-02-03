require "include"

shader = nil
palette = nil
palette_index = 3
elapsed = 0

love.load = function()
    shader = love.graphics.newShader("noba.glsl")
    palette = love.graphics.newImage("noba_palette.png")
    palette:setFilter("linear")
end

love.update = function(delta)
    elapsed = elapsed + delta
end

love.draw = function()
    if shader ~= nil then
        --[[
        shader:send("palette_texture", palette)
        shader:send("palette_y_index", palette_index)
        shader:send("time", elapsed)
        ]]--
        love.graphics.setShader(shader)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
        love.graphics.setShader(nil)
    end
end

love.keypressed = function(which)
    if which == "space" then
        shader =love.graphics.newShader("noba.glsl")
    elseif which == "up" then
        palette_index = clamp(palette_index + 1, 1, 10)
    elseif which == "down" then
        palette_index = clamp(palette_index - 1, 1, 10)
    end
end