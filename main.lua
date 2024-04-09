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

local party_sprite = bt.PartySprite(scene, boulder)

function distribute_status()
    local statuses = {}
    for i = 1, 10 do
        if rt.random.toss_coin(0.7) then
            table.insert(statuses, bt.Status("TEST"))
        else
            table.insert(statuses, bt.Status("OTHER_TEST"))
        end
    end

    for entity in values(scene._entities) do
        for key in keys(entity.status) do
            entity.status[key] = nil
        end
    end

    for status in values(statuses) do
        status:realize()
        local status_entity = rt.random.choose(scene._entities)
        status_entity.status[status] = rt.random.integer(0, 5)
    end
end

rt.current_scene:set_debug_draw_enabled(false)

local info = bt.VerboseInfo()
local info_hidden = false

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.A then
        scene:play_animation(boulder, "KILLED")
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.DOWN then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.SELECT then
    end
    --[[
    if which == rt.InputButton.A then
        local entity = rt.random.choose(scene._entities)
        local entity_config = {
            name = entity:get_name(),
            hp_current = entity:get_hp(),
            hp_base = entity:get_hp_base(),
            should_censor = false,
            attack_current = entity.attack_base,
            attack_preview = nil,
            defense_current = entity.defense_base,
            defense_preview = nil,
            speed_current = entity.speed_base,
            speed_preview = nil,
            status = {
                [bt.Status("TEST")] = 2,
                [bt.Status("OTHER_TEST")] = 3
            },
            stance = bt.Stance("TEST")
        }
        info:_create_entity_page(entity, entity_config)
    elseif which == rt.InputButton.B then
        local status = bt.Status("TEST")
        info:_create_status_page(status)
    elseif which == rt.InputButton.X then
        local move = bt.Move("TEST_MOVE")
        info:_create_move_page(move, bt.Stance("NEUTRAL"))
    elseif which == rt.InputButton.Y then
        local move = bt.Move("TEST_MOVE")
        info:_create_move_page(move, bt.Stance("TEST"))
    elseif which == rt.InputButton.UP then
        scene:play_animation(boulder, "STATUS_LOST", bt.Status("TEST"))
    elseif which == rt.InputButton.DOWN then
    elseif which == rt.InputButton.LEFT then
        scene:play_animation(boulder, "MOVE", boulder)
    elseif which == rt.InputButton.RIGHT then
        scene:play_animation(boulder, "HELPED_UP")
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.SELECT then
    end
    ]]--
end)

love.load = function()
    love.window.setMode(1600 / 1.5, 900 / 1.5, {
        vsync = -1, -- adaptive vsync, may tear but tries to stay as close to 60hz as possible
        msaa = 8,
        stencil = true,
        resizable = true,
        borderless = false
    })
    love.window.setTitle("rat_game")
    love.filesystem.setIdentity("rat_game")
    rt.current_scene:realize()

    -- TODO
    party_sprite:realize()
    local w, h, size = rt.graphics.get_width(), rt.graphics.get_height(), 100
    party_sprite:fit_into(w / 2 - 2 * 0.5 * size, h - size, 2 * size, size)

    info:realize()
    info:fit_into(20, 20, 2 * 3/16 * rt.graphics.get_width(), rt.graphics.get_height())
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

    --party_sprite:draw()
    info:draw()
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