require "include"

local tileset = ow.TilesetConfig("debug_tileset_objects")

--local config = ow.StageConfig("debug_stage")
--config:realize()

love.draw = function()
    love.graphics.draw(tileset._texture_atlas, 20, 20)
    --tileset:_draw(4, 50, 50)
end