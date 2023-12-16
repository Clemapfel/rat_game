require "include"

rt.add_scene("debug")

entity = bt.Entity("TEST_ENTITY")
entity.attack_level = 0
entity.defense_level = 0
entity.speed_level = 0

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

bar:add_mark(25)
bar:add_mark(50)
bar:add_mark(75)

entity:add_status_ailment(status)
info = bt.PartyInfo(entity)
info:set_margin(10)
info._hp_bar:set_value(75)
info:set_alignment(rt.Alignment.CENTER)

box = rt.SwipeLayout()
for i = -4, 4, 1 do
    box:push_back(bt.StatLevelTooltip(rt.random.choose({bt.Stat.ATTACK, bt.Stat.DEFENSE, bt.Stat.SPEED}), i))
end

rt.current_scene:set_child(info)
input = rt.add_input_controller(rt.current_scene.window)
input:signal_connect("pressed", function(self, which)

    if meta.is_nil(switch) then switch = true end

    local speed = 0.1
    if which == rt.InputButton.A then
        if switch then
            entity:set_hp(entity:get_hp_base())
            entity:set_speed_level(3)
            switch = not switch
        else
            entity:set_hp(1)
            entity:set_speed_level(-3)
            switch = not switch
        end
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