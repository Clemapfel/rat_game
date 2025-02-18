require "include"

shader = nil
palette = nil
palette_index = 3
mode = 0
mode_aa_eps = 0.01
elapsed = 0
time_since_last_pulse = 0

local shader_path = "noba2.glsl"

love.load = function()
    shader = love.graphics.newShader(shader_path)
    palette = love.graphics.newImage("noba_palette.png")
    palette:setFilter("linear")


    label = rt.Label("<outline_color=BLACK><wave><rainbow><b>SHADERS</b></rainbow></wave></outline_color>", rt.settings.font.default_huge)
    label:realize()
    label:set_justify_mode(rt.JustifyMode.CENTER)
    local label_w, label_h = label:measure()

    local w, h =  love.graphics.getDimensions();
    label:fit_into(0, 0.5 * h - 0.5 * label_h, w, h)

end

love.update = function(delta)
    elapsed = elapsed + delta
    time_since_last_pulse = time_since_last_pulse + delta
    label:update(delta)
end

love.draw = function()
    if shader ~= nil then

        --shader:send("palette_texture", palette)
        --shader:send("palette_y_index", palette_index)
        --shader:send("color_mode_toon_aa_eps", mode_aa_eps)
        shader:send("time", elapsed)
        --shader:send("time_since_last_pulse", time_since_last_pulse)

        love.graphics.setShader(shader)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
        love.graphics.setShader(nil)
    end

    label:draw()
end

love.keypressed = function(which)
    if which == "x" then
        shader = love.graphics.newShader(shader_path)
        elapsed = 0
        time_since_last_pulse = POSITIVE_INFINITY
        dbg("recompile")
    elseif which == "space" then
        time_since_last_pulse = 0
    elseif which == "up" then
        palette_index = clamp(palette_index + 1, 1, 10)
    elseif which == "down" then
        palette_index = clamp(palette_index - 1, 1, 10)
    end
end