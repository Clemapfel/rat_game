require "include"

local font_size = 10
local font = love.graphics.newFont("assets/fonts/NotoSans/NotoSans-Bold.ttf", font_size, {
    sdf = true
})

local str = "########"
local text = love.graphics.newTextBatch(font, str)

local shader = rt.Shader("common/glyph_sdf.glsl")
local elapsed = 0

love.update = function(delta)
    elapsed = elapsed + delta
    shader:send("elapsed", elapsed)
    shader:send("is_effect_rainbow", true)
    shader:send("is_effect_shake", true)
    shader:send("is_effect_wave", true)
    shader:send("draw_outline", true)
    shader:send("outline_color", {rt.color_unpack(rt.Palette.PURPLE)})
    shader:send("font_size", font_size)
    shader:send("n_visible_characters", rt.InterpolationFunctions.SINE_WAVE(elapsed, 0.2) * #str + 1)
end

love.draw = function()
    love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
    love.graphics.setColor(1, 1, 1, 1)
    shader:bind()
    shader:send("draw_outline", true)
    love.graphics.draw(text, 200, 200)
    shader:send("draw_outline", false)
    love.graphics.draw(text, 200, 200)
    shader:unbind()
end

love.keypressed = function()
    shader = rt.Shader("common/glyph_sdf.glsl")
end

--[[
profiler_active = false

STATE = rt.GameState()
STATE:set_loading_screen(rt.LoadingScreen.DEFAULT)
STATE:initialize_debug_state()

camera = STATE:get_camera()

local draw_state = true
input = rt.InputController()
input:signal_connect("keyboard_pressed", function(_, which)
    if which == rt.KeyboardKey.ONE then
        STATE:set_current_scene(mn.InventoryScene)
    elseif which == rt.KeyboardKey.TWO then
        STATE:set_current_scene(mn.OptionsScene)
    elseif which == rt.KeyboardKey.THREE then
        STATE:set_current_scene(mn.KeybindingScene)
    elseif which == rt.KeyboardKey.FOUR then
        STATE:set_current_scene(bt.BattleScene)
    elseif which == rt.KeyboardKey.FIVE then
        STATE:set_current_scene(rt.LeakScene)
    elseif which == rt.KeyboardKey.ZERO then
        STATE:set_current_scene(nil)
    elseif which == rt.KeyboardKey.RETURN then
        profiler_active = not profiler_active
    elseif which == rt.KeyboardKey.ESCAPE then
    end

    if which == rt.KeyboardKey.SPACE then
        --camera:set_angle(rt.random.number(-math.pi, math.pi))
        --camera:set_scale(rt.random.number(1 / 4, 4))
        --camera:set_position(love.mouse.getPosition())
    elseif which == rt.KeyboardKey.B then
        --camera:shake(10 / 60)
    elseif which == rt.KeyboardKey.X then
        --camera:skip()
    end
end)

love.load = function()
    STATE:load()

    STATE:set_current_scene(bt.BattleScene)--mn.InventoryScene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    STATE:update(delta)
end

love.draw = function()
    STATE:draw()
end

love.resize = function(new_width, new_height)
    STATE:resize(new_width, new_height)
end

love.run = function()
    STATE:run()
end
]]--
