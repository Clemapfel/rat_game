require "include"

rt.add_scene("debug")

entity = bt.Entity("TEST_ENTITY")

move = bt.Action("TEST_MOVE")
consumable = bt.Action("TEST_CONSUMABLE")
intrinsic = bt.Action("TEST_INTRINSIC")

for _, action in pairs({move, consumable, intrinsic}) do
    entity:add_action(action)
end

selection_menu = bt.ActionSelectionMenu(entity)
thumbnail = bt.ActionSelectionThumbnail(move)

swipe = rt.SwipeLayout(rt.Orientation.VERTICAL)

swipes = {}
for i = 1, 3 do
    local to_insert = rt.SwipeLayout(rt.Orientation.HORIZONTAL)
    for _, id in pairs({"ANALYZE", "NO_ACTION", "PROTECT", "STRIKE", "WISH"}) do
        move = bt.Action(id)
        to_insert:push_back(bt.ActionSelectionThumbnail(move))
    end
    to_insert:set_show_selection(true)
    to_insert:set_modifies_focus(false)
    table.insert(swipes, to_insert)
    swipe:push_back(to_insert)
end

swipe:set_show_selection(false)
swipe:set_modifies_focus(true)
swipe:set_allow_wrap(false)

equipment = bt.Equipment("TEST_EQUIPMENT")
status = bt.StatusAilment("TEST_STATUS")

bar = rt.LevelBar(0, 100, 50)
bar:set_color(rt.Palette.HP)
bar:set_value(45)
bar:set_expand_vertically(false)
bar:set_minimum_size(0, rt.settings.margin_unit)
bar:set_margin_horizontal(rt.settings.margin_unit)

rt.current_scene:set_child(bar)
input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)

    local speed = 0.1
    if which == rt.InputButton.A then
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.X then
        swipe:jump_to(1)
    elseif which == rt.InputButton.Y then
        swipe:jump_to(6)
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.DOWN then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.R then
    elseif which == rt.InputButton.L then
    end

    if which == rt.InputButton.A then
    end
end)

function love.load()
    rt.current_scene:realize()
end

local mesh = love.graphics.newMesh(rt.VertexFormat, {
    {0, 0, 0,  0, 0, 1, 1, 1, 1}
}, "points")

function love.draw()

    love.graphics.clear(1, 0, 1, 1)
    rt.current_scene:draw()
    
    -- scene rendering
    rt.current_scene:draw()
end

function love.update()
    rt.current_scene:update(love.timer.getDelta())
end