require "include"

local tileset = ow.TilesetConfig("debug_tileset_objects")

--local config = ow.StageConfig("debug_stage")
--config:realize()

local texture = rt.Texture("assets/sprites/why.png")
local batch = ow.SpriteBatch(texture)

local x, y, w1 = 50, 50, 200
local to_update = batch:add(50, 50, w1, w1, 0, 0, 1, 1, false, false, 0.5 * math.pi)
local w2 = 300
batch:add(x + w1, y, w2, w2, 0, 0, 1, 1)
local w3 = 100
batch:add(x + w1 + w2, y, w3, w3, 0, 0, 1, 1)

love.draw = function()
    batch:draw()
end

local elapsed = 0
local flip_elapsed = 0
local flip = true
love.update = function(delta)
    elapsed = elapsed + delta
    flip_elapsed = flip_elapsed + delta
    if flip_elapsed > 0.5 then
        flip = not flip
        flip_elapsed = 0
    end

    batch:set(to_update, 50, 50, w1, w1, 0, 0, 1, 1, flip, flip, elapsed)

end