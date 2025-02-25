require "include"

normal_map = love.graphics.newImage("assets/normal_map_up.png")
image = love.graphics.newImage("assets/normal_map_down.png")
local scale = 6
image_x, image_y = 0, 0

love.window.setMode(image:getWidth() * scale, image:getHeight() * scale, {
    resizable = true,
    vsync = rt.VSyncMode.OFF
})

shader = rt.Shader("common/normal_map_lighting.glsl")
n_lights = 1

light_format = {
    { name = "position", format = "floatvec2" },
    { name = "intensity", format = "float" },
    { name = "color", format = "floatvec3" },
}

light_buffer = love.graphics.newBuffer(light_format, n_lights, {
    usage = "dynamic",
    shaderstorage = true
})

light_data = {}
do
    local x, y = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    for i = 1, n_lights do
        table.insert(light_data, {
            x, y,
            1,
            1, 1, 1
        })
    end
    light_buffer:setArrayData(light_data)
end

love.load = function()
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.resize = function(screen_w, screen_h)
    local image_w, image_h = image:getDimensions()
    image_w = image_w * scale
    image_h = image_h * scale

    image_x = 0.5 * screen_w - 0.5 * image_w
    image_y = 0.5 * screen_h - 0.5 * image_h
end

light_elapsed = 0
love.update = function(delta)
    light_elapsed = light_elapsed + delta
    local mouse_x, mouse_y = love.mouse.getPosition()

    local intensity = love.math.perlinNoise(light_elapsed, light_elapsed)

    light_data[1] = {
        mouse_x, mouse_y,
        intensity,
        1, 1, 1
    }

    local distance = 400
    for i = 2, n_lights do
        local fraction = (i - 2) / (n_lights - 1)
        local x, y = rt.translate_point_by_angle(mouse_x, mouse_y, distance, fraction * math.pi * 2 + light_elapsed)
        local color = rt.hsva_to_rgba(rt.HSVA(fraction, 1, 1, 1))
        light_data[i] = {
            x, y,
            intensity,
            color.r, color.g, color.b
        }
    end

    light_buffer:setArrayData(light_data)
    shader:send("light_buffer", light_buffer)
    shader:send("n_lights", n_lights)
end

love.keypressed = function(_, which)
    if which == "escape" then
        shader:recompile()
        dbg("recompile")
    end
end

love.draw = function()
    love.graphics.scale(scale, scale)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, image_x, image_y)

    love.graphics.printf(love.timer.getFPS(), 0, 0, POSITIVE_INFINITY)
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
    shader:bind()
    love.graphics.draw(normal_map, image_x, image_y)
    shader:unbind()
    rt.graphics.set_blend_mode()
end