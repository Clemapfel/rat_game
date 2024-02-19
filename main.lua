require("include")

local texture_w = rt.settings.audio_processor.window_size / 2
local texture_h = 100
local shader = rt.Shader("assets/shaders/fourier_transform_visualization.glsl")
local image_data_format = "r8"
local image = love.image.newImageData(texture_w, texture_h, image_data_format)
local texture = love.graphics.newImage(image)
texture:setFilter("linear", "linear", 2)

--shader:send("_spectrum_size", {texture_w, rt.settings.audio_processor.window_size / texture_w})
local texture_shape = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
texture_shape._native:setTexture(texture)

local col_i = 0
local processor = rt.AudioProcessor("test_music_mono.mp3", "assets/sound")
processor.on_update = function(spectrum, angle)
    if col_i >= texture_h then
        clock = rt.Clock()
        image = love.image.newImageData(texture_w, texture_h, image_data_format)
        col_i = 0
        println(clock:get_elapsed())
    end

    for i = 1, #spectrum do
        local value = spectrum[i]
        image:setPixel(i-1, col_i, value, value, value, 1)
    end

    texture:replacePixels(image)
    shader:send("_spectrum", texture)
    col_i = col_i + 1
end

rt.current_scene = rt.add_scene("debug")
local scene = ow.OverworldScene()
rt.current_scene:set_child(scene)

rt.current_scene.input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        scene._player:set_position(350, 330)
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.DOWN then
    end
end)

-- ##

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:run()
end

love.draw = function()
    love.graphics.clear(0.8, 0, 0.8, 1)
    rt.current_scene:draw()

    shader:bind()
    texture_shape:draw()
    shader:unbind()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
    processor:update()
end
