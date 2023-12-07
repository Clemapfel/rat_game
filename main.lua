require "include"

function connect_emmy_lua_debugger()
    -- entry point for JetBrains IDE debugger
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.2/EmmyLua/debugger/emmy/linux/?.so'
    local dbg = require('emmy_core')
    dbg.tcpConnect('localhost', 8172)

    love.errorhandler = function(msg)
        dbg.breakHere()
        return nil -- exit
    end
end
try_catch(connect_emmy_lua_debugger)
io.stdout:setvbuf("no") -- makes it so love2d error message is printed to console immediately

-- #############################

rt.add_scene("debug")

action = bt.Action("TEST_ACTION")
action_tooltip = bt.ActionTooltip(action)
action_item = bt.ActionListItem(action)

equipment = bt.Equipment("TEST_EQUIPMENT")
equipment_tooltip = bt.EquipmentTooltip(equipment)
equipment_item = bt.EquipmentListItem(equipment)

status = bt.StatusAilment("TEST_STATUS")
status_tooltip = bt.StatusTooltip(status)

entity = bt.Entity("TEST_ENTITY")
entity.attack_level = -2
entity.defense_level = 1
entity.speed_level = -1
entity:add_status_ailment(bt.StatusAilment("TEST_STATUS_TEMPORARY"))
entity:add_status_ailment(bt.StatusAilment("TEST_STATUS_INFINITE"))
entity_tooltip = bt.EntityTooltip(entity)

rt.current_scene:set_child(equipment_tooltip)

input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, button)
    if button == rt.InputButton.A then
        equipment_tooltip._tooltip:set_show_sprite(equipment_tooltip._tooltip:get_show_sprite())
    end
end)

-- #############################

--- @brief startup
function love.load()
    love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {
        resizable = true
    })
    love.window.setTitle("rat_game")

    rt.current_scene:realize()
end

--- @brief update tick
function love.update()
    rt.current_scene:update(love.timer.getDelta())
end

--- @brief draw step
function love.draw()

    rt.current_scene:draw()

    function show_fps()
        local text = love.graphics.newText(love.graphics.getFont(), tostring(math.round(love.timer.getFPS())))
        local w, h = text:getWidth(), text:getHeight()
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(text, love.graphics.getWidth() - w, 0)
    end
    show_fps()
end

--- @brief shutdown
function love.quit()
    rt.Palette:export("palette.png")
end

::exit::