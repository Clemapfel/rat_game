require "include"

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