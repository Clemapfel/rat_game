--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    return meta.new(bt.BattleScene, {
        _temp = bt.OrderedBox(),
        _temp_objects = {},
        _temp_object_to_widget = {},

        _health = bt.HealthBar(0, 100),
        _input = rt.InputController()
    })
end)

--- @brief
function bt.BattleScene:_add_item(object)
    local widget = rt.LabeledSprite(object:get_sprite_id())
    self._temp_object_to_widget[object] = widget
    self._temp:add(widget, not meta.isa(object, bt.Consumable))

    table.insert(self._temp_objects, object)
end

--- @override
function bt.BattleScene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for object in range(
        bt.Status("DEBUG_STATUS"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.GlobalStatus("DEBUG_GLOBAL_STATUS")
    ) do
        self:_add_item(object)
    end

    self._temp:realize()
    self._health:realize()

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)
end

--- @override
function bt.BattleScene:create_from_state(state)

end

--- @override
function bt.BattleScene:size_allocate(x, y, width, height)
    local temp_w, temp_h = 0.5 * width, 50
    self._temp:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h, temp_w, temp_h)
    self._health:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h + 2 * temp_h, temp_w, temp_h)
end

--- @override
function bt.BattleScene:draw()
    self._temp:draw_bounds()
    self._temp:draw()
    self._health:draw()
end

--- @override
function bt.BattleScene:update(delta)
    self._temp:update(delta)
    self._health:update(delta)
end

--- @override
function bt.BattleScene:make_active()
    self._is_active = true
end

--- @override
function bt.BattleScene:make_inactive()
    self._is_active = false
end

--- @brief
function bt.BattleScene:_handle_button_pressed(which)
    if false then
        if which == rt.InputButton.L then
            self._temp:activate(self._temp_object_to_widget[self._temp_objects[rt.random.integer(1, sizeof(self._temp_objects))]], function(widget)
                widget:set_label(tostring(rt.random.integer(1, sizeof(123))))
            end)
        elseif which == rt.InputButton.R then
            local index = rt.random.integer(1, sizeof(self._temp_objects))
            self._temp:remove(self._temp_object_to_widget[self._temp_objects[index]], function()
                self._temp_object_to_widget[self._temp_objects[index]] = nil
                table.remove(self._temp_objects, index)
            end)
        elseif which == rt.InputButton.X then
            self:_add_item(bt.Status("DEBUG_STATUS"))
        elseif which == rt.InputButton.Y then
            self:_add_item(bt.Consumable("DEBUG_CONSUMABLE"))
        elseif which == rt.InputButton.B then
            self._temp:set_opacity(self._temp:get_opacity() - 0.1)
        elseif which == rt.InputButton.A then
            self._temp:skip()
        end
    end

    if which == rt.InputButton.L then
        local current = self._health:get_value()
        current = current - 10
        self._health:set_value(current)
    elseif which == rt.InputButton.R then
        local current = self._health:get_value()
        current = current + 10
        self._health:set_value(current)
    elseif which == rt.InputButton.X then
    elseif which == rt.InputButton.Y then
    elseif which == rt.InputButton.B then
    elseif which == rt.InputButton.A then
    end
end