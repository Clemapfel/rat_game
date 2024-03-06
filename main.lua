require "include"

audio = rt.AudioVisualizer("assets/sound/test_music_02.mp3")
audio:play()

local visualizer_initialized = false
local spectrum_image, spectrum_texture, energy_image, energy_texture
local spectrum_format = "rgba16"
local energy_format = "rgba16"
local col_i = 0
local texture_h = 10e3

local shader = rt.Shader("assets/shaders/audio_visualizer_debug.glsl")
local shape = {}
local active = false

audio.on_update = function(coefficients, energies)
    if not visualizer_initialized then

        spectrum_image = love.image.newImageData(texture_h, #coefficients, spectrum_format)
        spectrum_texture = love.graphics.newImage(spectrum_image)

        energy_image = love.image.newImageData(texture_h, #energies, energy_format)
        energy_texture = love.graphics.newImage(energy_image)

        shape = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
        visualizer_initialized = true
    end

    if col_i >= texture_h then
        spectrum_image = love.image.newImageData(texture_h, #coefficients, spectrum_format)
        energy_image = love.image.newImageData(texture_h, #energies, energy_format)
        col_i = 0
    end

    for i, value in ipairs(coefficients) do
        spectrum_image:setPixel(col_i, i - 1, value, value, value, 1)
    end

    for i, value in ipairs(energies) do
        energy_image:setPixel(col_i, i - 1, value, 0, 0, 1)
    end

    spectrum_texture:replacePixels(spectrum_image)
    energy_texture:replacePixels(energy_image)

    shader:send("_coefficients", spectrum_texture)
    --shader:send("_energies", energy_texture)
    shader:send("_index", col_i)
    shader:send("_max_index", texture_h)

    col_i = col_i + 1
end

rt.SpriteAtlas = rt.SpriteAtlas()
rt.SpriteAtlas:initialize("assets/sprites")

rt.current_scene = ow.OverworldScene()
rt.current_scene._player:set_position(150, 150)
rt.current_scene:add_stage("debug_map", "assets/stages/debug")

sprite = ow.OverworldSprite(rt.current_scene, "debug/bouncy_ball")
rt.current_scene:add_entity(sprite, 50, 50)

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    println(which)
    if which == rt.InputButton.R then
        audio:play()
    elseif which == rt.InputButton.L then
        audio:pause()
    elseif which == rt.InputButton.SELECT then
        audio:stop()
    end
end)

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:realize()
end

love.draw = function()
    love.graphics.clear(0.8, 0.2, 0.8, 1)
    rt.current_scene:draw()

    shader:bind()
    shape:draw()
    shader:unbind()

    do -- show fps
        local fps = tostring(love.timer.getFPS())
        local margin = 3
        love.graphics.setColor(1, 1, 1, 0.75)
        love.graphics.print(fps, rt.graphics.get_width() - love.graphics.getFont():getWidth(fps) - 2 * margin, 0.5 * margin)
    end
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.AnimationHandler:update(delta)
    rt.current_scene:update(delta)

    audio:update()
end

love.quit = function()
end