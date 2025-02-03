shader = nil
palette = nil
elapsed = 0

love.load = function()
    shader = love.graphics.newShader("noba.glsl")
    palette = love.graphics.newImage("noba_palette.png")
end

love.update = function(delta)
    elapsed = elapsed + delta
end

love.draw = function()
    shader:send("resolution", {love.graphics.getDimensions()})
    shader:send("paletteTexture", palette)
    shader:send("paletteResolution", {palette:getDimensions()})
    shader:send("paletteIndex", 4)
    shader:send("time", elapsed)
    love.graphics.setShader(shader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setShader(nil)
end

love.keypressed = function(which)
    if which == "space" then
        shader = love.graphics.newShader("noba.glsl")
    end
end