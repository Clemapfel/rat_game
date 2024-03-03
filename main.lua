require "include"

local sprite_atlas = rt.SpriteAtlas("assets/sprites")
sprite_atlas:initialize()

rt.current_scene = ow.OverworldScene()
rt.current_scene._player:set_position(150, 150)
rt.current_scene:add_stage("debug_map", "assets/stages/debug")

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

love.quit = function()

end