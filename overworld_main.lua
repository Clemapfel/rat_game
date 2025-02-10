require "include"

local tileset = ow.TilesetConfig("debug_tileset_objects")

local config = ow.StageConfig("debug_stage")
config:realize()

love.draw = function()
    tileset:_draw()
end