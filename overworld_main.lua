require "include"

local tileset = ow.TilesetConfig("debug_tileset_objects")

local config = ow.StageConfig("debug_stage")
config:realize()
config:_construct_spritebatches()
config:_construct_object_sprites()
config:_construct_hitboxes()

local offset_x, offset_y = 0, 0
local scale = 1

love.load = function()
    love.window.updateMode(
        1600 / 1.5,
        800 / 1.5
    )
end

love.draw = function()
    local w, h = love.graphics.getDimensions()
    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.rectangle("fill", 0, 0, w, h)

    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(0.5 * w, 0.5 * h)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-0.5 * w, -0.5 * h)
    love.graphics.translate(offset_x, offset_y)
    config:draw()
    love.graphics.pop()

    --tileset:draw()
end

local scroll_margin_factor = 0.1
local scroll_speed = 300
local scale_speed = 1
local mouse_active = false

love.mousefocus = function(b)
    mouse_active = b
end

love.keypressed = function(which)
    if which == "space" then
        config:realize()
        config:_construct_spritebatches()
        config:_construct_object_sprites()
        config:_construct_hitboxes()
    end
end

love.update = function(delta)
    if mouse_active then
        local x, y = love.mouse.getPosition()
        local w, h = love.graphics.getDimensions()

        local left_x = scroll_margin_factor * w
        local right_x = (1 - scroll_margin_factor) * w
        local x_width = scroll_margin_factor * w
        if x < left_x then
            offset_x = offset_x + math.abs(x - left_x) / x_width * scroll_speed * delta
        elseif x > right_x then
            offset_x = offset_x - math.abs(x - right_x) / x_width * scroll_speed * delta
        end

        local up_y = scroll_margin_factor * h
        local down_y = (1 - scroll_margin_factor) * h
        local y_width = scroll_margin_factor * h
        if y < up_y then
            offset_y = offset_y + math.abs(y - up_y) / y_width * scroll_speed * delta
        elseif y > down_y then
            offset_y = offset_y - math.abs(y - down_y) / y_width * scroll_speed * delta
        end
    end

    if love.keyboard.isDown("x") then
        scale = scale + scale_speed * delta
    elseif love.keyboard.isDown("y") then
        scale = scale - scale_speed * delta
    end
end