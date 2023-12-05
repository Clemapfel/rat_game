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

--rt.current_scene:set_child(status_tooltip)
function snapshot_widget(widget)

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

clock = rt.Clock()
sprite = rt.Sprite(env.equipment_spritesheet, "default")
rt.current_scene:set_child(sprite)

local depth_buffer = {
    color = love.graphics.newCanvas(w, h, {format = "rgba8"}),
    depth = love.graphics.newCanvas(w, h, {format = "depth24"}),
}
depth_buffer.canvas = {depth_buffer.color, depthstencil = depth_buffer.depth}


depth = 0
function set_depth()
    local shape = sprite._shape
    for i = 1, shape:get_n_vertices() do
        local x, y, z = shape:get_vertex_position(1)
        shape:set_vertex_position(1, x, y, depth)
    end

    println(depth)
end

input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, button)
    if button == rt.InputButton.A then
        status_tooltip._tooltip:set_show_sprite(not status_tooltip._tooltip:get_show_sprite())
    elseif button == rt.InputButton.UP then
        depth = depth + 10
        set_depth(depth)
    elseif button == rt.InputButton.DOWN then
        depth = depth - 10
        set_depth(depth)
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

    --rt.current_scene:draw()

    love.graphics.setCanvas(depth_buffer.canvas)
    --love.graphics.setMeshCullMode("back")

    sprite._shape:draw()

    --love.graphics.setMeshCullMode("none")
    --love.graphics.setDepthMode()
    love.graphics.setCanvas()

    love.graphics.clear(1, 0, 1, 1, true, 1)
    love.graphics.draw(depth_buffer.color)

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