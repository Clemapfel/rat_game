--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    return meta.new(bt.BattleScene, {
        _temp = bt.OrderedBox(),
        _temp_objects = {},
        _temp_object_to_widget = {},

        _health = bt.HealthBar(0, 100),
        _speed = bt.SpeedValue(55),

        _log = rt.TextBox(),

        _verbose_info = mn.VerboseInfoPanel(),
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
    self._speed:realize()

    self._verbose_info:realize()
    self._verbose_info:set_backdrop_visible(false)

    self._log:realize()

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)
end

--- @override
function bt.BattleScene:create_from_state(state)
    self._log:clear()
end

--- @override
function bt.BattleScene:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local temp_w, temp_h = 0.5 * width, 50
    self._temp:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h, temp_w, temp_h)
    self._health:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h + 2 * temp_h, temp_w, temp_h)
    self._speed:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h + 3 * temp_h, temp_w, temp_h)


    local outer_margin = 2 * m
    local log_margin = 10 * outer_margin
    self._log:fit_into(log_margin, outer_margin, width - 2 * log_margin, height - 2 * outer_margin)

    local verbose_w = 0.3 * width
    self._verbose_info:fit_into(x + width - verbose_w - outer_margin, outer_margin, verbose_w, height - 2 * outer_margin)

    -- TODO
    self._verbose_info:show(bt.Status("DEBUG_STATUS"))
    -- TODO
end

--- @override
function bt.BattleScene:draw()
    self._temp:draw_bounds()
    self._temp:draw()
    self._health:draw()
    self._speed:draw()

    self._verbose_info:draw_bounds()
    self._verbose_info:draw()
    self._log:draw()
end

--- @override
function bt.BattleScene:update(delta)
    self._temp:update(delta)
    self._health:update(delta)
    self._speed:update(delta)
    self._verbose_info:update(delta)
    self._log:update(delta)
end

--- @override
function bt.BattleScene:make_active()
    self._is_active = true
end

--- @override
function bt.BattleScene:make_inactive()
    self._is_active = false
end

_i = 1

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

    if false then
        if which == rt.InputButton.L then
            local current = self._health:get_value()
            current = current - 10
            self._health:set_value(current)

            local current = self._speed:get_value()
            current = current - 5
            self._speed:set_value(current)
        elseif which == rt.InputButton.R then
            local current = self._health:get_value()
            current = current + 10
            self._health:set_value(current)

            local current = self._speed:get_value()
            current = current + 5
            self._speed:set_value(current)
        elseif which == rt.InputButton.X then
        elseif which == rt.InputButton.Y then
        elseif which == rt.InputButton.B then
        elseif which == rt.InputButton.A then
        end
    end

    if which == rt.InputButton.A then
        local text = rt.random.string(64, " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ")
        local colors = {"RED", "GREEN", "BLUE", "YELLOW"}
        self._log:clear()
        self._log:append("<color=" .. colors[_i] .. ">" .. text .. "</color>")
        _i = _i + 1
        if _i > sizeof(colors) then
            _i = 1
        end
    elseif which == rt.InputButton.B then
        self._log:skip()
    elseif which == rt.InputButton.UP then
        self._log:scroll_up()
    elseif which == rt.InputButton.DOWN then
        self._log:scroll_down()
    elseif which == rt.InputButton.X then
        self._log:close()
    elseif which == rt.InputButton.Y then
        self._log:present()
    elseif which == rt.InputButton.L then
        self._log:set_scrolling_active(not self._log:get_scrolling_active())
    end
end