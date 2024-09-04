rt.settings.menu.keybinding_scene = {
    text_atlas_id = "menu/keybinding_scene"
}

--- @class rt.KeybindingScene
mn.KeybindingScene = meta.new_type("KeybindingScene", rt.Scene, function(state)
    return meta.new(mn.KeybindingScene, {
        _state = state,
        _items = {},                   -- Table<Table<mn.KeybindingScene.Item>>
        _button_to_item = {},          -- Table<rt.InputButton, mn.KeybindingScene.Item>
        _restore_default_item = nil,   -- mn.KeybindingScene.Item
        _accept_label = nil,            -- mn.KeybindingScene.Item
        _accept_frame = rt.Frame(),
        _go_back_label = nil,           -- mn.KeybindingScene.Item
        _go_back_frame = rt.Frame(),
        _restore_defaults_label = nil,
        _restore_defaults_frame = rt.Frame(),

        _heading_label = nil,
        _heading_frame = rt.Frame(),
        _control_indicator = rt.ControlIndicator(),
        _dialog_shadow = rt.Rectangle(0, 0, 1, 1),
        _invalid_binding_dialog = nil, -- mn.MessageDialog
        _selection_graph = rt.SelectionGraph(),

        _input = rt.InputController(),
        _assignment_active = false,
        _assignment_button = nil, -- rt.InputButton
        _skip_frame = 0
    })
end, {
    button_layout = {
        {rt.InputButton.A, rt.InputButton.B, rt.InputButton.X, rt.InputButton.Y},
        {rt.InputButton.UP, rt.InputButton.RIGHT, rt.InputButton.DOWN, rt.InputButton.LEFT},
        {rt.InputButton.L, rt.InputButton.R, rt.InputButton.START, rt.InputButton.SELECT}
    }
})

--- @override
function mn.KeybindingScene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local labels = rt.TextAtlas:get(rt.settings.menu.keybinding_scene.text_atlas_id)
    self._accept_label = rt.Label(labels.accept)
    self._go_back_label = rt.Label(labels.go_back)
    self._heading_label = rt.Label(labels.heading)
    self._restore_defaults_label = rt.Label(labels.restore_defaults)

    for label in range(self._accept_label, self._go_back_label, self._heading_label, self._restore_defaults_label) do
        label:realize()
    end

    for frame in range(self._accept_frame, self._go_back_frame, self._heading_frame, self._restore_defaults_frame) do
        frame:realize()
    end

    self._items = {}
    for button_row in values(self.button_layout) do
        local row = {}
        for button in values(button_row) do
            local to_insert = {
                button = button,
                label = rt.Label(labels[button]),
                frame = rt.Frame(),
                gamepad_indicator = rt.KeybindingIndicator(),
                keyboard_indicator = rt.KeybindingIndicator()
            }
            self._button_to_item[button] = to_insert

            to_insert.label:realize()
            to_insert.frame:realize()
            to_insert.gamepad_indicator:realize()
            to_insert.keyboard_indicator:realize()
            table.insert(row, to_insert)
        end
        table.insert(self._items, row)
    end

    self._control_indicator:create_from({
        {rt.ControlIndicatorButton.ALL_DIRECTIONS, "Select"},
        {rt.ControlIndicatorButton.A, "Remap"},
    })
    self._control_indicator:realize()

    self:create_from_state(self._state)

    local scene = self
    self._input:signal_disconnect_all()
    self._input:signal_connect("pressed", function(_, which)
        if scene._skip_frame > 0 then return end
        if not scene._assignment_active then
            scene._selection_graph:handle_button(which)
        end
    end)

    self._input:signal_connect("keyboard_pressed", function(_, which)
        if scene._skip_frame > 0 then return end
        if scene._assignment_active then
            scene:_finish_assignment(which)
        end
    end)

    self._input:signal_connect("gamepad_pressed", function(_, which)
        if scene._skip_frame > 0 then return end
        if scene._assignment_active then
            scene:_finish_assignment(which)
        end
    end)
end

--- @override
function mn.KeybindingScene:create_from_state(state)
    for item_row in values(self._items) do
        for item in values(item_row) do
            local keyboard, gamepad = rt.InputControllerState:get_keybinding(item.button)
            item.gamepad_indicator:set_key(gamepad)
            item.keyboard_indicator:set_key(keyboard)
        end
    end
end

--- @override
function mn.KeybindingScene:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local xm, ym = 2 * m, m
    local heading_w, heading_h = self._heading_label:measure()

    local control_w, control_h = self._control_indicator:measure()

    local outer_margin = 2 * m
    local current_x, current_y = x + outer_margin, y + outer_margin
    local heading_frame_w, heading_frame_h = heading_w + 2 * xm, control_h
    self._heading_frame:fit_into(current_x, current_y, heading_frame_w, heading_frame_h)
    self._heading_label:fit_into(current_x + xm, current_y + 0.5 * heading_frame_h - 0.5 * heading_h, POSITIVE_INFINITY, heading_frame_h)
    self._control_indicator:fit_into(x + width - outer_margin - control_w, current_x, control_w, control_h)

    current_y = current_y + control_h + m
    local item_x, item_y = current_x, current_y

    local max_label_w, max_label_h, max_row_n = NEGATIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY
    for item_row in values(self._items) do
        local row_n = 0
        for item in values(item_row) do
            local label_w, label_h = item.label:measure()
            max_label_w = math.max(max_label_w, label_w)
            row_n = row_n + 1
        end
        max_row_n = math.max(max_row_n, row_n)
    end

    max_label_w = math.max(max_label_w, select(1, self._accept_label:measure()))
    max_label_w = math.max(max_label_w, select(1, self._go_back_label:measure()))

    local indicator_w = 6.5 * m
    local indicator_h = indicator_w
    local item_w = xm + max_label_w + 2 * xm + indicator_w + xm
    local item_h = math.max(max_label_h, indicator_h) + 2 * ym
    local item_xm = (width - 2 * xm - max_row_n * item_w) / (max_row_n - 1)
    for item_row in values(self._items) do
        for item in values(item_row) do
            local label_w, label_h = item.label:measure()
            item.frame:fit_into(item_x, item_y, item_w, item_h)
            item.label:fit_into(item_x + xm, item_y + 0.5 * item_h - 0.5 * label_h, POSITIVE_INFINITY, item_h)

            for indicator in range(item.keyboard_indicator, item.gamepad_indicator) do
                indicator:fit_into(item_x + item_w - xm - indicator_w, item_y + 0.5 * item_h - 0.5 * indicator_h, indicator_w, indicator_h)
            end

            item_x = item_x + item_w + item_xm
        end
        item_x = current_x
        item_y = item_y + item_h + m
    end



    local last_row_h = control_h
    local last_row_x, last_row_y = item_x, item_y
    for frame_label in range(
        {self._accept_frame, self._accept_label},
        {self._go_back_frame, self._go_back_label},
        {self._restore_defaults_frame, self._restore_defaults_label}
    ) do
        local frame = frame_label[1]
        local label = frame_label[2]
        frame:fit_into(last_row_x, last_row_y, item_w, last_row_h)
        local label_w, label_h = label:measure()
        label:fit_into(last_row_x + xm, last_row_y + 0.5 * last_row_h - 0.5 * label_h, POSITIVE_INFINITY)

        last_row_x = last_row_x + item_w + item_xm
    end

    self._selection_graph:clear()
    self:_regenerate_selection_nodes()
end

--- @breif
function mn.KeybindingScene:_regenerate_selection_nodes()
    local item_rows = {{}}
    local n_rows = sizeof(self._items)
    for row_i, item_row in ipairs(self._items) do
        for item in values(item_row) do
            local node = rt.SelectionGraphNode(item.frame:get_bounds())
            node.item = item
            table.insert(item_rows[row_i], node)
            self._selection_graph:add(node)
        end
        if row_i < n_rows then
            table.insert(item_rows, {})
        end
    end

    local scene = self
    for row_i, row in ipairs(item_rows) do
        for col_i, node in ipairs(row) do
            node:set_left(row[col_i - 1])
            node:set_right(row[col_i + 1])

            local up_row = item_rows[row_i - 1]
            if up_row ~= nil then node:set_up(up_row[col_i]) end
            local below_row = item_rows[row_i + 1]
            if below_row ~= nil then node:set_down(below_row[col_i]) end

            node:signal_connect("enter", function(self)
                self.item.frame:set_selection_state(rt.SelectionState.ACTIVE)
            end)

            node:signal_connect("exit", function(self)
                self.item.frame:set_selection_state(rt.SelectionState.INACTIVE)
            end)

            node:signal_connect(rt.InputButton.A, function(self)
                scene:_start_assignment(self.item.button)
            end)
        end
    end

    local accept_node = rt.SelectionGraphNode(self._accept_frame:get_bounds())
    local go_back_node = rt.SelectionGraphNode(self._go_back_frame:get_bounds())
    local restore_defaults_node = rt.SelectionGraphNode(self._restore_defaults_frame:get_bounds())
    self._selection_graph:add(accept_node, go_back_node, restore_defaults_node)

    local bottom_nodes = {}
    for node_frame in range(
        {accept_node, self._accept_frame},
        {go_back_node, self._go_back_frame},
        {restore_defaults_node, self._restore_defaults_frame}
    ) do
        local node = node_frame[1]
        local frame = node_frame[2]

        node:signal_connect("enter", function(_)
            frame:set_selection_state(rt.SelectionState.ACTIVE)
        end)

        node:signal_connect("exit", function(_)
            frame:set_selection_state(rt.SelectionState.INACTIVE)
        end)

        local min_x_distance = POSITIVE_INFINITY
        local closest_node
        for node in values(item_rows[#item_rows]) do
            local distance = math.abs(frame:get_bounds().x - node:get_bounds().x)
            if distance < min_x_distance then
                min_x_distance = distance
                closest_node = node
            end
        end

        closest_node:set_down(node)
        node:set_up(closest_node)
        table.insert(bottom_nodes, node)
    end

    for i, node in ipairs(bottom_nodes) do
        node:set_left(bottom_nodes[i - 1])
        node:set_right(bottom_nodes[i + 1])
    end

    self._selection_graph:set_current_node(item_rows[1][1])
end

--- @override
function mn.KeybindingScene:update(delta)
    self._skip_frame = self._skip_frame - 1
end

--- @brief
function mn.KeybindingScene:_start_assignment(button)
    meta.assert_enum(button, rt.InputButton)
    self._assignment_button = button
    self._assignment_active = true
    self._skip_frame = 2

    local unselected_opacity = 0.6
    for row in values(self._items) do
        for item in values(row) do
            if item.button ~= button then
                item.frame:set_opacity(unselected_opacity)
                item.label:set_opacity(unselected_opacity)
                item.keyboard_indicator:set_opacity(unselected_opacity)
                item.gamepad_indicator:set_opacity(unselected_opacity)
            end
        end
    end
end

--- @brief
function mn.KeybindingScene:_finish_assignment(which)
    local item = self._button_to_item[self._assignment_button]
    if meta.is_enum_value(which, rt.KeyboardKey) then
        item.keyboard_indicator:set_key(which)
    else
        item.gamepad_indicator:set_key(which)
    end
    self._assignment_active = false

    for row in values(self._items) do
        for item in values(row) do
            item.frame:set_opacity(1)
            item.label:set_opacity(1)
            item.keyboard_indicator:set_opacity(1)
            item.gamepad_indicator:set_opacity(1)
        end
    end
end

--- @override
function mn.KeybindingScene:draw()
    if self._is_realized ~= true then return end
    self._heading_frame:draw()
    self._heading_label:draw()
    self._control_indicator:draw()

    local keyboard_or_gamepad = self._input:get_input_method() == rt.InputMethod.KEYBOARD
    for item_row in values(self._items) do
        for item in values(item_row) do
            item.frame:draw()
            item.label:draw()

            if keyboard_or_gamepad then
                item.keyboard_indicator:draw()
            else
                item.gamepad_indicator:draw()
            end
        end
    end

    self._go_back_frame:draw()
    self._go_back_label:draw()

    self._accept_frame:draw()
    self._accept_label:draw()

    self._restore_defaults_frame:draw()
    self._restore_defaults_label:draw()
end