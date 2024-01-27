require("include")

rt.current_scene = rt.add_scene("debug")
background = bt.BattleBackground("mint_wave")
rt.current_scene:set_child(background)

sprites = {}
for i = 1, 5 do
    local color = rt.random.choose({"RED", "GREEN", "BLUE", "PINK", "PURPLE"})
    local label = rt.Label("<o><color=" .. color .. ">" .. rt.random.string(5) .. "</color></o>")
    local spacer = rt.Spacer()
    spacer:set_color(rt.color_darken(rt.Palette[rt.random.choose({"RED", "GREEN", "BLUE", "PINK", "PURPLE"})], 0.4))
    local overlay = rt.OverlayLayout()
    overlay:push_overlay(spacer)
    overlay:push_overlay(label)
    table.insert(sprites, overlay)
end
local x, y, w, h = 50, 150, love.graphics.getWidth() / #sprites - 25, 100
local m = (love.graphics.getWidth() - #sprites * w) / (#sprites + 1)
x = x + m

local hue = 0.05
for _, sprite in pairs(sprites) do
    sprite:realize()
    sprite:fit_into(x, rt.random.number(y, y + 50), w, h)
    x = x + w + m
    hue = hue + (0.9 / #sprites)
end

state_queue = rt.StateQueue()
rt.current_scene.input:signal_connect("pressed", function(_, which)
    local values = {}
    for i = 1, #sprites do
        table.insert(values, rt.random.integer(9, 9999))
    end

    if which == rt.InputButton.A then
        state_queue:push_back(bt.Animation.HP_GAINED(sprites, values))
    elseif which == rt.InputButton.B then
        state_queue:push_back(bt.HPLostAnimation(sprites, values))
    elseif which == rt.InputButton.X then
        state_queue:push_back(bt.EnemyAppearedAnimation(sprites))
    elseif which == rt.InputButton.Y then
        state_queue:push_back(bt.EnemyDisappearedAnimation(sprites))
    elseif which == rt.InputButton.R then
        local directions = {}
        local stats = {}
        for i = 1, #sprites do
            table.insert(directions, rt.random.choose({rt.Direction.UP, rt.Direction.DOWN}))
            table.insert(stats, rt.random.choose({bt.Stat.ATTACK, bt.Stat.DEFENCE, bt.Stat.SPEED}))
        end
        state_queue:push_back(bt.StatChangedAnimation(sprites, directions, stats))
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.DOWN then
    end
end)

-- ######################

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
    love.graphics.clear(1, 0, 1, 1)
    rt.current_scene:draw()

    for _, sprite in pairs(sprites) do
        sprite:draw()
    end
    state_queue:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
    state_queue:update(delta)
end
