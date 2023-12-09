require "include"

function connect_emmy_lua_debugger()
    -- entry point for JetBrains IDE debugger
    io.stdout:setvbuf("no")
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.2/EmmyLua/debugger/emmy/linux/?.so'
    local dbg = require('emmy_core')
    dbg.tcpConnect('localhost', 8172)

    love.errorhandler = function(error_message)
        dbg.breakHere()
        return nil -- exit
    end
end
try_catch(connect_emmy_lua_debugger)

-- ###########################

rt.add_scene("debug")

equipment = bt.Equipment("TEST_EQUIPMENT")
status_inf = bt.StatusAilment("TEST_STATUS_INFINITE")
status_temp = bt.StatusAilment("TEST_STATUS_TEMPORARY")

entity = bt.Entity("TEST_ENTITY")

entity_tooltip = bt.EntityTooltip(entity)
rt.current_scene:set_child(entity_tooltip)

local n = 1
input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)
    if which == rt.InputButton.A then
        entity_tooltip._tooltip:set_show_sprite(not entity_tooltip._tooltip:get_show_sprite())
    elseif which == rt.InputButton.RIGHT then
        n = n + 1
        bar:set_n_filled(n)
    elseif which == rt.InputButton.LEFT then
        n = n - 1
        bar:set_n_filled(n)
    end
end)

bar = rt.NotchBar(10)
rt.current_scene:set_child(bar)

-- ###########################

function love.load()
    rt.current_scene:realize()
end

function love.update()
    rt.current_scene:update(love.timer.getDelta())
end

function love.draw()
    rt.current_scene:draw()
end

function love.quit()
    --rt.Palette:export("palette.png")
end