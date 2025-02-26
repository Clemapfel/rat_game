require "include"

rt = {}

require "common.color"
require "physics.physics"

local world
local bodies = {}

love.load = function()
    local data = love.image.newImageData("assets/palette_input.png")
    local col_i_to_lightness = {}
    for i = 1, data:getWidth() do
        local r, g, b, a = data:getPixel(i - 1, 0)
        local l, c, h, a = rt.rgba_to_lcha(r, g, b, a)
        col_i_to_lightness[i] = l
    end

    for row_i = 1, data:getHeight() do
        local l, c, h, a = rt.rgba_to_lcha(data:getPixel(1, row_i - 1))
        for i = 1, data:getWidth() do
            data:setPixel(i - 1, row_i - 1, rt.lcha_to_rgba(col_i_to_lightness[i], c, h, 1))
        end
    end

    love.filesystem.mountFullPath(love.filesystem.getSource() .. "/assets", "", "readwrite")
    assert(nil ~= data:encode("png", "palette_out.png", love.filesystem.getSource() .. "/assets"))
end