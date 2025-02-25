require "include"


image = rt.Image("assets/sprites/test.png")

shader = love.graphics.newShader([[
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px)
{
    // source: https://github.com/Nikaoto/subpixel/blob/master/subpixel_d7samurai.frag
    vec2 texture_resolution = textureSize(tex, 0);
    uv *= texture_resolution;
    uv = floor(uv) + min(fract(uv) / fwidth(uv), 1.0) - 0.5;
    uv /= texture_resolution;
    return color * texture(tex, uv);
}
]])

texture_01 = rt.Texture(image)
texture_01:set_scale_mode(rt.TextureScaleMode.NEAREST)
sprite_01 = rt.VertexRectangle(50, 50, 50, 50)
sprite_01:set_texture(texture_01)
sprite_01:set_color(rt.Palette.TRUE_WHITE)

shader_02 = rt.Shader("assets/shaders/sprite_scale_correction.glsl")
texture_02 = rt.Texture(image)
texture_02:set_scale_mode(rt.TextureScaleMode.LINEAR)
sprite_02 = rt.VertexRectangle(0, 0, 1, 1)
sprite_02:set_texture(texture_02)
sprite_02:set_color(rt.Palette.TRUE_MAGENTA)
--shader_02:send("texture_resolution", {image:get_width(), image:get_height()})

scale_x, scale_y = 1, 1
rotation = 0
sprite_01_origin_x, sprite_01_origin_y = 0, 0
sprite_02_origin_x, sprite_02_origin_y = 0, 0

input = rt.InputController()

function reformat()
    local w, h = rt.graphics.get_width(), rt.graphics.get_height()

    local image_w, image_h = image:get_size()
    image_w = image_w * scale_x
    image_h = image_h * scale_y

    local x, y = 0.25 * w - 0.5 * image_w, 0.5 * h - 0.5 * image_h
    sprite_01:reformat(
        x, y,
        x + image_w, y,
        x + image_w, y + image_h,
        x, y + image_h
    )
    sprite_01_origin_x = x + 0.5 * image_w
    sprite_01_origin_y = y + 0.5 * image_h

    x, y = 0.75 * w - 0.5 * image_w, 0.5 * h - 0.5 * image_h
    sprite_02:reformat(
        x, y,
        x + image_w, y,
        x + image_w, y + image_h,
        x, y + image_h
    )
    sprite_02_origin_x = x + 0.5 * image_w
    sprite_02_origin_y = y + 0.5 * image_h
end

love.draw = function()
    local offset_x, offset_y = 0.5 * rt.graphics.get_width(), 0.5 * rt.graphics.get_height()

    love.graphics.origin()
    love.graphics.translate(sprite_01_origin_x, sprite_01_origin_y)
    love.graphics.rotate(rotation)
    love.graphics.translate(-sprite_01_origin_x, -sprite_01_origin_y)
    sprite_01:draw()

    love.graphics.origin()
    love.graphics.translate(sprite_02_origin_x, sprite_02_origin_y)
    love.graphics.rotate(rotation)
    love.graphics.translate(-sprite_02_origin_x, -sprite_02_origin_y)
    shader_02:bind()
    sprite_02:draw()
    shader_02:unbind()
end

stop = true

love.update = function(dt)
    local scale_speed = 1
    local rotation_speed = (2 * math.pi) * 0.2

    if input:is_down(rt.InputButton.A) then
        stop = false
    end

    if stop == true then return end

    local should_reformat = false
    if input:is_down(rt.InputButton.UP) then
        scale_x = scale_x * (1 + dt) * scale_speed
        scale_y = scale_y * (1 + dt) * scale_speed
        should_reformat = true
    end

    if input:is_down(rt.InputButton.DOWN) then
        scale_x = scale_x / ((1 + dt) * scale_speed)
        scale_y = scale_y / ((1 + dt) * scale_speed)
        should_reformat = true
    end

    if input:is_down(rt.InputButton.RIGHT) then
        rotation = rotation + dt * rotation_speed
        should_reformat = true
    end

    if input:is_down(rt.InputButton.LEFT) then
        rotation = rotation - dt * rotation_speed
        should_reformat = true
    end

    scale_x = scale_x * (1 + (rotation_speed / 6) * dt)
    scale_y = scale_x
    rotation = rotation + rotation_speed * 0.01
    reformat()
end

love.resize = function()
    reformat()
end

love.load = function()
    love.window.setMode(600, 600, {
        vsync = -1, -- adaptive vsync, may tear but tries to stay as close to 60hz as possible
        msaa = 8,
        stencil = true,
        resizable = true,
        borderless = false
    })
    love.resize()
end