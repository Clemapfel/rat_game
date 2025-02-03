require "include"

shader = nil
elapsed = 0

love.load = function()
    shader = love.graphics.newShader("noba.glsl")

    local palette = love.graphics.newImage(6, 0)
    palette:setPixel(0, 0, rt.color_unpack(rt.Palette.RED_2))
    palette:setPixel(1, 0, rt.color_unpack(rt.Palette.RED_3))
    palette:setPixel(2, 0, rt.color_unpack(rt.Palette.RED_4))
    palette:setPixel(3, 0, rt.color_unpack(rt.Palette.RED_5))



end

elapsed = elapsed + delta
love.update = function(delta)
    shader:send("time", elapsed)
end