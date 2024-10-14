require "include"

love.window.setMode(800, 600, {
    resizable = true
})

local sprite_scale = 1
local sprite_x, sprite_y, sprite_w, sprite_h
local sprite = {
    _texture = love.graphics.newImage("assets/why.png"),
    draw = function(self)
        love.graphics.draw(self._texture, sprite_x, sprite_y)
    end,
    measure = function()
        return sprite_w * sprite_scale, sprite_h * sprite_scale
    end,

    get_bounds = function()
        return rt.AABB(sprite_x, sprite_y, sprite_w * sprite_scale, sprite_h * sprite_scale)
    end
}

sprite_w, sprite_h = sprite._texture:getDimensions()
sprite_x, sprite_y = 0.5 * love.graphics.getWidth() - 0.5 * sprite_w, 0.5 * love.graphics.getHeight() - 0.5 * sprite_h

local animation = bt.Animation.DISSOLVE(sprite)
animation:realize()

love.update = function(delta)
    if love.keyboard.isDown("space") then
        animation:update(delta)
    end
end

love.draw = function()
    animation:draw()
end


--[[


player_x, player_y = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
player_radius = 50

local scale = 2

love.draw = function()

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    local normalization_factor
    if w > h then
        normalization_factor = w / h
        love.graphics.translate(player_x * normalization_factor, player_y)
        love.graphics.scale(scale * normalization_factor, scale)
        love.graphics.translate(-player_x, -player_y)
    else
        normalization_factor = w
        love.graphics.translate(player_x , player_y * normalization_factor)
        love.graphics.scale(scale, scale * normalization_factor)
        love.graphics.translate(-player_x, -player_y)
    end

    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.circle("fill", player_x, player_y, player_radius)

    local mouse_x, mouse_y = love.mouse.getPosition()

    love.graphics.push()
    love.graphics.translate(player_x, player_y)
    love.graphics.rotate(math.atan2(player_y - mouse_y, player_x - mouse_x) - (math.pi) / 2)
    love.graphics.translate(-player_x, -player_y)

    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.setLineWidth(5)
    love.graphics.line(player_x, player_y, player_x, player_y - player_radius * 2)

    love.graphics.pop()
end

love.resize = function(w, h)

end


--[[
background = rt.Background()
background:set_implementation(rt.Background.MIDI_TILING)

require "midi.midi_input"
midi = rt.MidiInput()

base = 0
hi = 0
speed = 1

world = b2.World(0, 1000)
shape_circle = b2.Circle(20)
body_y = rt.graphics.get_height() * 0.8
base_body = b2.Body(world, b2.BodyType.DYNAMIC, 0.25 * rt.graphics.get_width(), body_y)
base_shape = b2.CircleShape(base_body, shape_circle)

hi_body = b2.Body(world, b2.BodyType.DYNAMIC, 0.75 * rt.graphics.get_width(), body_y)
hi_shape = b2.CircleShape(hi_body, shape_circle)

speed_body = b2.Body(world, b2.BodyType.DYNAMIC, 0.5 * rt.graphics.get_width(), body_y - shape_circle:get_radius() * 3)
speed_shape = b2.CapsuleShape(speed_body, b2.Capsule(
    0, -1 * shape_circle:get_radius(),
    0, 1 * shape_circle:get_radius(),
    shape_circle:get_radius()
))

floor_body = b2.Body(world, b2.BodyType.STATIC,0.5 * rt.graphics.get_width(), body_y + shape_circle:get_radius())
floor_shape = b2.SegmentShape(floor_body, b2.Segment(
    -0.5 * rt.graphics.get_width(), 0,
    0.5 * rt.graphics.get_width(), 0
))

for body in range(hi_body, base_body, speed_body, floor_body) do
    body:set_rotation_fixed(true)
end

midi:signal_connect("message", function(type, value)
    value = value * 2 - 1
    if type == rt.MidInput.is_pad(type) then

    end
end)

love.keypressed = function(which)
    local magnitude = 50
    if which == "m" then
        hi_body:apply_linear_impulse(0, -magnitude)
    elseif which == "y" then
        base_body:apply_linear_impulse(0, -magnitude)
    end
end

love.load = function()
    background:realize()
    background:fit_into(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
end

love.update = function(delta)
    world:step(delta)
    background:update(delta, speed, base, hi)
end

love.resize = function(w, h)
    background:fit_into(0, 0, w, h)
end

love.draw = function()
    background:draw()

    world:draw()
end
]]--