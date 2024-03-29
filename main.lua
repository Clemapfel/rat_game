require "include"-- Initializes color values

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

local status_entity = boulder
local status_01 = bt.Status("TEST")
local status_02 = bt.Status("OTHER_TEST")

for status in range(status_01, status_02) do
    status:realize()
end

status_entity.status[status_01] = 0
status_entity.status[status_02] = 2

local bar = bt.StatusBar()
bar:add(small_ufo, status_01)
bar:add(small_ufo, status_02)

rt.current_scene:set_debug_draw_enabled(true)

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        if rt.random.toss_coin() then
            bar:add(small_ufo, status_01)
        else
            bar:remove(small_ufo, status_01)
        end
    elseif which == rt.InputButton.B then
        if rt.random.toss_coin() then
            bar:add(small_ufo, status_02)
        else
            bar:remove(small_ufo, status_02)
        end
    elseif which == rt.InputButton.X then
        scene._priority_queue:set_selected()
        scene._priority_queue:set_knocked_out()
    elseif which == rt.InputButton.Y then
        scene._priority_queue:set_is_hidden(not scene._priority_queue:get_is_hidden())
    elseif which == rt.InputButton.UP then

    elseif which == rt.InputButton.DOWN then

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
        resizable = true,
        borderless = false
    })
    love.window.setTitle("rat_game")
    love.filesystem.setIdentity("rat_game")
    rt.current_scene:realize()

    bar:realize()
    bar:fit_into(0, 0, rt.graphics.get_width(), 100)

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

    bar:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.AnimationHandler:update(delta)
    rt.current_scene:update(delta)

    bar:update(delta)
end

love.resize = function()
    rt.current_scene:size_allocate(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

love.quit = function()
end