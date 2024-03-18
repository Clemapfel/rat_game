require "include"

rt.SpriteAtlas = rt.SpriteAtlas()
rt.SpriteAtlas:initialize("assets/sprites")

rt.SoundAtlas = rt.SoundAtlas()
rt.SoundAtlas:initialize("assets/sound_effects")

local scene = bt.BattleScene()
rt.current_scene = scene

local small_ufo = bt.BattleEntity(scene, "SMALL_UFO")
local boulder = bt.BattleEntity(scene, "BALL_WITH_FACE")
local sprout_01 = bt.BattleEntity(scene, "WALKING_SPROUT")
local sprout_02 = bt.BattleEntity(scene, "WALKING_SPROUT")
local mole = bt.BattleEntity(scene, "GAMBLER_MOLE")

for entity in range(small_ufo, boulder, sprout_01, sprout_02, mole) do
    scene:add_entity(entity)
end

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        --[[
        local i = rt.random.integer(1, #scene._enemy_sprites)
        local sprite = scene._enemy_sprites[i]
        --sprite:add_animation(bt.Animation.HP_GAINED(scene, sprite, rt.random.integer(0, 100)))
        sprite:add_continuous_animation(bt.Animation.KNOCKED_OUT_SUSTAIN(scene, sprite))
        ]]--
        scene:add_entity(bt.BattleEntity(scene, "SMALL_UFO"))
    elseif which == rt.InputButton.B then
        local i = rt.random.integer(1, #scene._enemy_sprites)
        local sprite = scene._enemy_sprites[i]
        sprite:add_animation(bt.Animation.HP_LOST(scene, sprite, rt.random.integer(0, 100)))
    elseif which == rt.InputButton.X then
        local i = rt.random.integer(1, #scene._enemy_sprites)
        local sprite = scene._enemy_sprites[i]
        sprite:add_animation(bt.Animation.PLACEHOLDER_MESSAGE(scene, sprite, "ALREADY DEAD"))
    elseif which == rt.InputButton.Y then
        local i = rt.random.integer(1, #scene._enemy_sprites)
        local sprite = scene._enemy_sprites[i]
        sprite:add_animation(bt.Animation.ENEMY_APPEARED(scene, sprite))
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.SELECT then
    end
end)

love.load = function()
    love.window.setMode(1600 / 1.5, 900 / 1.5, {
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
end

love.resize = function()
    rt.current_scene:size_allocate(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

love.quit = function()
end

--[[
rt.current_scene = ow.OverworldScene()
rt.current_scene._player:set_position(150, 150)
rt.current_scene:add_stage("debug_map", "assets/stages/debug")

sprite = ow.OverworldSprite(rt.current_scene, "debug/bouncy_ball")
rt.current_scene:add_entity(sprite, 50, 50)

]]--

--[[
local visualizer_initialized = false
local spectrum_image, spectrum_texture, energy_image, energy_texture
local spectrum_format = "rgba16"
local energy_format = "rgba16"
local col_i = 0
local texture_h = 10e3

local shader = rt.Shader("assets/shaders/audio_visualizer_debug.glsl")
local active = false

audio.on_update = function(coefficients)
    if not visualizer_initialized then
        spectrum_image = love.image.newImageData(texture_h, #coefficients, spectrum_format)
        spectrum_texture = love.graphics.newImage(spectrum_image)
        spectrum_texture:setFilter("nearest", "nearest")

        shape = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
        visualizer_initialized = true
    end

    if col_i >= texture_h then
        spectrum_image = love.image.newImageData(texture_h, #coefficients, spectrum_format)
        col_i = 0
    end

    for i, value in ipairs(coefficients) do
        spectrum_image:setPixel(col_i, i - 1, value, value, value, 1)
    end

    spectrum_texture:replacePixels(spectrum_image)

    shader:send("_coefficients", spectrum_texture)
    --shader:send("_energies", energy_texture)
    shader:send("_index", col_i)
    shader:send("_max_index", texture_h)

    col_i = col_i + 1
end

 if shader ~= nil and shape ~= nil then
shader:bind()
        shape:draw()
        shader:unbind()

end
]]--
