require "include"

local sprite_texture, sdf_texture_a, sdf_texture_b, sprite
local texture_w, texture_h
local screen_w, screen_h = 800, 600
local padding = 10
local max_distance_buffer

local jump_flood_shader, render_shader
local a_or_b = true

love.load = function()
    sprite = rt.Sprite("why")
    sprite:realize()
    local sprite_w, sprite_h = sprite:measure()
    sprite_w = sprite_w * 2
    sprite_h = sprite_h * 2
    sprite:fit_into(0, 0, sprite_w, sprite_h)

    texture_w, texture_h = 800 + 2 * padding, 600 + 2 * padding
    sprite_texture = rt.RenderTexture(texture_w, texture_h, 0, rt.TextureFormat.RGBA8, true)
    sdf_texture_a = rt.RenderTexture(texture_w, texture_h, 0, rt.TextureFormat.RG32UI, true)
    sdf_texture_b = rt.RenderTexture(texture_w, texture_h, 0, rt.TextureFormat.RG32UI, true)

    jump_flood_shader = rt.ComputeShader("smoke_jump_flood.glsl")
    render_shader = rt.Shader("smoke_render.glsl")

    love.graphics.push()
    sprite_texture:bind()
    love.graphics.clear(0, 0, 0, 0)
    -- Correctly center the sprite by using sprite_h for the y-axis translation
    love.graphics.translate(0.5 * texture_w - 0.5 * sprite_w, 0.5 * texture_h - 0.5 * sprite_h)
    sprite:draw()
    sprite_texture:unbind()
    love.graphics.pop()

    max_distance_buffer = rt.GraphicsBuffer(jump_flood_shader:get_buffer_format("max_distance_buffer"), 1)

    render_shader:send("max_distance_buffer", max_distance_buffer._native)
    jump_flood_shader:send("max_distance_buffer", max_distance_buffer._native)

    jump_flood_shader:send("mode", 0) -- init
    jump_flood_shader:send("init_texture", sprite_texture._native)
    jump_flood_shader:send("input_texture", sdf_texture_a._native)
    jump_flood_shader:send("output_texture", sdf_texture_b._native)
    jump_flood_shader:dispatch(texture_w, texture_h)

    jump_flood_shader:send("mode", 1) -- compute sdf
    local jump_distance = ffi.new("int32_t", 128)
    while (jump_distance > 0) do
        if a_or_b then
            jump_flood_shader:send("input_texture", sdf_texture_a._native)
            jump_flood_shader:send("output_texture", sdf_texture_b._native)
        else
            jump_flood_shader:send("input_texture", sdf_texture_b._native)
            jump_flood_shader:send("output_texture", sdf_texture_a._native)
        end

        jump_flood_shader:send("jump_distance", tonumber(jump_distance))
        jump_flood_shader:dispatch(texture_w, texture_h)
        jump_distance = jump_distance / 2

        a_or_b = not a_or_b
    end
end

love.update = function(delta)

end

love.draw = function()
    sprite_texture:draw()

    if a_or_b then
        render_shader:send("image", sdf_texture_b._native)
    else
        render_shader:send("image", sdf_texture_a._native)
    end

    render_shader:bind()
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    render_shader:unbind()

    do
        local fps = tostring(love.timer.getFPS())
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(fps, rt.graphics.get_width() - love.graphics.getFont():getWidth(fps) - 2 * margin, 0.5 * margin)
    end
end

love.keypressed = function(which)
    if which == "b" then love.load() end
end