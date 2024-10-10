require "include"

local animation = rt.TimedAnimation(1, 0, 2, rt.InterpolationFunctions.LINEAR)
animation:signal_connect("done", function(self)
    dbg("done")
end)

state = rt.GameState()
state:set_loading_screen(rt.LoadingScreen.DEFAULT)
state:initialize_debug_state()

world = b2.World

local background = rt.Background()

local draw_state = true
input = rt.InputController()
input:signal_connect("keyboard_pressed", function(_, which)
    if which == rt.KeyboardKey.ONE then
        state:set_current_scene(mn.InventoryScene)
    elseif which == rt.KeyboardKey.TWO then
        state:set_current_scene(mn.OptionsScene)
    elseif which == rt.KeyboardKey.THREE then
        state:set_current_scene(mn.KeybindingScene)
    elseif which == rt.KeyboardKey.FOUR then
        state:set_current_scene(bt.BattleScene)
    elseif which == rt.KeyboardKey.ESCAPE then
        println(rt.profiler.report())
    end
end)

local offset = 1
input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.UP then
        offset = offset + 0.5
        rt.Label.render_shader:send("shake_offset", offset)
    elseif which == rt.InputButton.DOWN then
        offset = offset - 0.5
        rt.Label.render_shader:send("shake_offset", offset)
    end
end)

label = rt.Label("<shake>I think you can do the Undertale one with just </shake><mono><b>Text:addf</b></mono><shake>, but mine are all </shake><wave><rainbow>SHADERS</rainbow></wave>", rt.settings.font.default_large, rt.settings.font.default_mono_large)
label:realize()
label:fit_into(50, 50, 500)
label:set_n_visible_characters(0)
label:update(0)

font = rt.settings.font.default[rt.FontStyle.REGULAR]
font = love.graphics.newFont("assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf", 20)
test = love.graphics.newTextBatch(font, "TEST ADNALSNUD")

component = rt.SoundComponent()
component:signal_connect("finished", function(_)
    println("done")
end)

input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        --component:play("test/alarm")
    elseif which == rt.InputButton.B then

    elseif which == rt.InputButton.DEBUG then
    end
end)

love.load = function()
    background:realize()
    state:_load()
    state:set_current_scene(mn.InventoryScene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

elapsed = 0
label:set_n_visible_characters(0)
love.update = function(delta)
    background:update(delta)
    state:_update(delta)
    --midi:update(delta)

    if love.keyboard.isDown("space") then
        label:update(delta)
        elapsed = elapsed + delta
        label:update_n_visible_characters_from_elapsed(elapsed, 20)
    end
end

love.draw = function()
    love.graphics.setColor(0.3, 0.1, 0.3,  1)
    love.graphics.rectangle("fill", 0, 0, rt.graphics.get_width(), rt.graphics.get_height())
    background:draw()
    if draw_state then
        rt.profiler.push("draw")
        --state:_draw()
        rt.profiler.pop("draw")
    end

    label:draw()
    --love.graphics.setColor(0, 0, 0, 1)
    --love.graphics.draw(test, 50, 50)
end

love.resize = function(new_width, new_height)
    background:fit_into(0, 0, new_width, new_height)
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end
