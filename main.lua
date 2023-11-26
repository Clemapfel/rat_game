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

equipment = bt.Equipment("TEST_EQUIPMENT")
slot = bt.EquipmentSlot(equipment)
tooltip = bt.EquipmentTooltip(equipment)
tooltip:set_expand(false)

box = rt.ListLayout(rt.Orientation.VERTICAL)
--box:push_back(tooltip)
--box:push_back(rt.Spacer(rt.RGBA(1, 1, 1, 0.5)))

rt.current_scene:set_child(tooltip)
rt.current_scene.input:signal_connect("pressed", function(_, button)
    if button == rt.InputButton.A then
        local w, h = tooltip:measure()
        local x, y = tooltip._vbox:get_position()
        println(x, " ", y, " ", w, " ", h)
    elseif button == rt.InputButton.B then
        indicator:set_direction(rt.Direction.NONE)
    elseif button == rt.InputButton.UP then
        indicator:set_direction(rt.Direction.UP)
    elseif button == rt.InputButton.RIGHT then
        indicator:set_direction(rt.Direction.RIGHT)
    elseif button == rt.InputButton.DOWN then
        indicator:set_direction(rt.Direction.DOWN)
    elseif button == rt.InputButton.LEFT then
        indicator:set_direction(rt.Direction.LEFT)
    end
end)

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

    function draw_guides()
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()

        love.graphics.setColor(0, 1, 1, 0.5)
        local lines = {}
        for _, x in pairs({0.25, 0.5, 0.75, 0.33, 0.66, 0, 1}) do
            table.insert(lines, rt.Line(x * w, 0, x * w, h))
            table.insert(lines, rt.Line(0, x * h, w, x * h))
        end

        local half_color = rt.RGBA(1, 1, 0, 1)
        local third_color = rt.RGBA(0, 1, 1, 1)
        local quarter_color = rt.RGBA(0, 1, 0, 1)
        local outline_color = rt.RGBA(1, 0, 1, 1)

        lines[1]:set_color(quarter_color)
        lines[2]:set_color(quarter_color)
        lines[3]:set_color(half_color)
        lines[4]:set_color(half_color)
        lines[5]:set_color(quarter_color)
        lines[6]:set_color(quarter_color)
        lines[7]:set_color(third_color)
        lines[8]:set_color(third_color)
        lines[9]:set_color(third_color)
        lines[10]:set_color(third_color)
        lines[11]:set_color(outline_color)
        lines[12]:set_color(outline_color)
        lines[13]:set_color(outline_color)
        lines[14]:set_color(outline_color)

        for _, line in pairs(lines) do
            line:draw()
        end
    end
    --draw_guides()

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