require "include"

local tileset = ow.TilesetConfig("debug_tileset_objects")

local config = ow.StageConfig("debug_stage")
config:realize()
config:_construct_spritebatches()

love.draw = function()
    config:draw()
end