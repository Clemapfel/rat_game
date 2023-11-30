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

list = rt.ListView()
list:push_back(rt.Spacer())
equipment = bt.Equipment("TEST_EQUIPMENT")

for i = 1, 3 do
    list:push_back(bt.EquipmentListItem(equipment))
end

--rt.current_scene:set_child(list)
rt.current_scene.input:signal_connect("pressed", function(_, button)
    if button == rt.InputButton.A then
        item._tooltip_layout:set_tooltip_visible(not item._tooltip_layout:get_tooltip_visible())
    elseif button == rt.InputButton.B then
    elseif button == rt.InputButton.UP then
    elseif button == rt.InputButton.RIGHT then
    elseif button == rt.InputButton.DOWN then
    elseif button == rt.InputButton.LEFT then
    end
end)

local x, y, w, h = 100, 100, 150, 75

local attributes = {
    rt.Vector2(x, y),
    rt.Vector2(x + w, y),
    rt.Vector2(x + w, y + h),
    rt.Vector2(x, y + h)
}

data = rt.VertexShape(table.unpack(attributes))
dot = rt.VertexShape(rt.Vector2(0, 0))
dot._native:attachAttribute(rt.VertexAttribute.POSITION, data._native)

data:set_draw_mode(rt.MeshDrawMode.POINTS)
dot:set_draw_mode(rt.MeshDrawMode.POINTS)

local attributes = {
    {x, y},
    {x + w, y},
    {x + w, y + h},
    {x, y + h}
}

data = love.graphics.newMesh(attributes, rt.MeshDrawMode.POINTS, rt.SpriteBatchUsage.DYNAMIC)
dot = love.graphics.newMesh({{0, 0}}, rt.MeshDrawMode.POINTS, rt.SpriteBatchUsage.DYNAMIC)

dot:attachAttribute(rt.VertexAttribute.POSITION, data, "perinstance")

-- TODO

effect = rt.PixelEffect(3000)
local w, h = love.graphics.getWidth(), love.graphics.getHeight()
for i = 1, effect:get_n_instances() do
    effect:set_instance_position(i, rt.random.number(0, w), rt.random.number(0, h), 0)
end

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

    effect:draw()

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