require "include"

local sprite_texture, sdf_texture_a, sdf_texture_b, sprite
local texture_w, texture_h
local screen_w, screen_h = 800, 600
local padding = 10
local max_distance_buffer

local jump_flood_shader, render_shader
local a_or_b = true
local elapsed = 0

love.load = function()
    love.window.setMode(screen_w, screen_h, {
        vsync = 0
    })

    sprite = rt.Sprite("why_opaque")
    sprite:realize()
    local sprite_w, sprite_h = sprite:measure()
    sprite_w = sprite_w * 1
    sprite_h = sprite_h * 1
    sprite:fit_into(0, 0, sprite_w, sprite_h)

    texture_w, texture_h = screen_w + 2 * padding, screen_h + 2 * padding
    sprite_texture = rt.RenderTexture(texture_w, texture_h, 0, rt.TextureFormat.RGBA8, true)
    sdf_texture_a = rt.RenderTexture(texture_w, texture_h, 0, rt.TextureFormat.RGBA32F, true)
    sdf_texture_b = rt.RenderTexture(texture_w, texture_h, 0, rt.TextureFormat.RGBA32F, true)

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

    jump = math.max(texture_w, texture_h) / 2
    jump_flood_shader:send("mode", 1) -- compute sdf
end

local allow_update = false
love.update = function(delta)
    if not love.keyboard.isDown("c") then return end
    elapsed = elapsed + delta

    if allow_update and jump > 0.5 then
        if a_or_b then
            jump_flood_shader:send("input_texture", sdf_texture_a._native)
            jump_flood_shader:send("output_texture", sdf_texture_b._native)
        else
            jump_flood_shader:send("input_texture", sdf_texture_b._native)
            jump_flood_shader:send("output_texture", sdf_texture_a._native)
        end

        jump_flood_shader:send("jump_distance", jump)
        jump_flood_shader:dispatch(texture_w, texture_h)

        a_or_b = not a_or_b
        jump = jump / 2
        allow_update = false
    end
end

love.draw = function()
    --sprite_texture:draw()

    render_shader:bind()
    render_shader:send("elapsed", elapsed)
    render_shader:send("init_texture", sprite_texture._native)
    if a_or_b then
        render_shader:send("sdf_texture", sdf_texture_a._native)
        sdf_texture_b:draw()
    else
        render_shader:send("sdf_texture", sdf_texture_b._native)
        sdf_texture_a:draw()
    end
    render_shader:unbind()

    do
        local fps = tostring(love.timer.getFPS())
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(fps, rt.graphics.get_width() - love.graphics.getFont():getWidth(fps) - 2 * margin, 0.5 * margin)
    end
end

love.keypressed = function(which)
    if which == "b" then love.load() elseif which == "space" then allow_update = true end
end