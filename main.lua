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

layout = rt.ListLayout(rt.Orientation.VERTICAL)
layout:push_back(action_tooltip)
layout:push_back(rt.Spacer())

list_view = rt.ListView()

profiler.start()
for i = 1, 50 do
    list_view:push_back(bt.ActionListItem(action))
end
profiler.stop()
println(profiler.report())

list_view:add_sort_mode("ascending", function(x, y)
    return meta.hash(x) < meta.hash(y)
end)

list_view:add_sort_mode("descending", function(x, y)
    return meta.hash(x) > meta.hash(y)
end)
list_view:set_sort_mode("ascending")

rt.current_scene:set_child(list_view)

function snapshot_widget(widget)
    meta.assert_widget(widget)
    local w, h = widget:measure()
    local x, y = widget:get_position()
    local canvas = love.graphics.newCanvas(w, h)

    if not widget:get_is_realized() then
        widget:realize()
    end
    widget:fit_into(rt.AABB(0, 0, w, h))

    love.graphics.setCanvas({
        canvas,
        stencil = true
    })
    --love.graphics.reset()
    widget:draw()
    love.graphics.setCanvas()

    return canvas
end

input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, button)
    if button == rt.InputButton.A then
        local current = list_view:get_sort_mode()
        if current == "ascending" then
            list_view:set_sort_mode("descending")
        else
            list_view:set_sort_mode("ascending")
        end
    elseif button == rt.InputButton.B then
        list_view:reformat()
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