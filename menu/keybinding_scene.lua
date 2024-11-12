--- @class rt.KeybindingScene
mn.KeybindingScene = meta.new_type("KeybindingScene", rt.Scene, function(state)
    return meta.new(mn.KeybindingScene, {
        _state = state,
        _input_method = rt.InputMethod.KEYBOARD,
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
        _selection_graph = rt.SelectionGraph(),
        _accept_node = nil, -- rt.SelectionGraphNode

        _input_controller = rt.InputController(),
        _assignment_active = false,
        _assignment_button = nil, -- rt.InputButton
        _skip_frame = 0,

        _confirm_load_default_dialog = nil, -- rt.MessageDialog
        _confirm_abort_dialog = nil, -- rt.MessageDialog
        _keybinding_invalid_dialog = nil, -- rt.MessageDialog

        _snapshots = {}, -- Table<rt.RenderTexture>
        _active_frame = nil, -- rt.Frame
        _active_label = nil, -- rt.Label
    })
end, {
    button_layout = {
        {rt.InputButton.A, rt.InputButton.UP,    rt.InputButton.START},
        {rt.InputButton.B, rt.InputButton.RIGHT, rt.InputButton.SELECT},
        {rt.InputButton.X, rt.InputButton.DOWN,  rt.InputButton.L},
        {rt.InputButton.Y, rt.InputButton.LEFT,  rt.InputButton.R},
    }
})

--- @override
function mn.KeybindingScene:realize()
    if self:already_realized() then return end

    self._input_method = self._input_controller:get_input_method()
    local labels = rt.Translation.keybindings_scene
    self._accept_label = rt.Label(labels.accept)
    self._go_back_label = rt.Label(labels.go_back)
    self._heading_label = rt.Label("TODO") -- initialized in input_method_changed
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
                label = rt.Label(rt.input_button_to_string(button)),
                frame = rt.Frame(),
                gamepad_indicator = rt.KeybindingIndicator(),
                gamepad_binding = nil,
                keyboard_indicator = rt.KeybindingIndicator(),
                keyboard_binding = nil,
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
        {rt.ControlIndicatorButton.A, labels.control_indicator_a},
        {rt.ControlIndicatorButton.ALL_DIRECTIONS, labels.control_indicator_all},
        {rt.ControlIndicatorButton.B, labels.control_indicator_b}
    })
    self._control_indicator:realize()

    local scene = self
    self._input_controller:set_treat_left_joystick_as_dpad(true)
    self._input_controller:signal_disconnect_all()

    local is_dialog_active = function()
        return self._confirm_load_default_dialog:get_is_active() or
            self._confirm_abort_dialog:get_is_active() or
            self._keybinding_invalid_dialog:get_is_active()
    end

    self._input_controller:signal_connect("pressed", function(_, which)
        if self._is_active == false or scene._skip_frame > 0 or is_dialog_active() then return end
        if not scene._assignment_active then
            if which == rt.InputButton.B then
                self:_exit_scene()
            else
                scene._selection_graph:handle_button(which)
            end
        end
    end)

    self._input_controller:signal_connect("keyboard_pressed", function(_, which)
        if self._is_active == false or scene._skip_frame > 0 or is_dialog_active() then return end
        if scene._assignment_active then
            scene:_finish_assignment(which)
        end
    end)

    self._input_controller:signal_connect("gamepad_pressed", function(_, which)
        if self._is_active == false or scene._skip_frame > 0 or is_dialog_active() then return end
        if scene._assignment_active then
            scene:_finish_assignment(which)
        end
    end)

    self._input_controller:signal_connect("input_method_changed", function(_, new)
        scene._input_method = new
        if scene._input_method == rt.InputMethod.KEYBOARD then
            scene._heading_label:set_text(labels.heading_keyboard)
        elseif scene._input_method == rt.InputMethod.GAMEPAD then
            scene._heading_label:set_text(labels.heading_gamepad)
        end

        if self:get_is_realized() then
            self:reformat()
        end
    end)

    self._confirm_load_default_dialog = rt.MessageDialog(
        labels.confirm_load_default_message,
        labels.confirm_load_default_submessage,
        rt.MessageDialogOption.ACCEPT, rt.MessageDialogOption.CANCEL
    )
    self._confirm_load_default_dialog:realize()

    self._confirm_load_default_dialog:signal_disconnect_all()
    self._confirm_load_default_dialog:signal_connect("selection", function(self, selection)
        if selection == rt.MessageDialogOption.ACCEPT then
            for item_row in values(scene._items) do
                for item in values(item_row) do
                    local keyboard, gamepad = scene._state:get_default_keybinding(item.button)
                    item.gamepad_indicator:create_from_gamepad_button(gamepad)
                    item.keyboard_indicator:create_from_keyboard_key(keyboard)
                end
            end
        end
        self:close()
    end)

    self._confirm_abort_dialog = rt.MessageDialog(
        labels.confirm_abort_message,
        labels.confirm_abort_submessage,
        rt.MessageDialogOption.ACCEPT, rt.MessageDialogOption.CANCEL
    )
    self._confirm_abort_dialog:realize()

    self._confirm_abort_dialog:signal_disconnect_all()
    self._confirm_abort_dialog:signal_connect("selection", function(self, selection)
        if selection == rt.MessageDialogOption.ACCEPT then
            self:_exit_scene()
        else
            -- do nothing
        end
        self:close()
    end)

    self._keybinding_invalid_dialog = rt.MessageDialog(
        labels.keybinding_invalid_message,
        "", -- set during present
        rt.MessageDialogOption.ACCEPT
    )
    self._keybinding_invalid_dialog:realize()

    self._keybinding_invalid_dialog:signal_disconnect_all()
    self._keybinding_invalid_dialog:signal_connect("selection", function(self, selection)
        self:close()
    end)

    self._input_controller:signal_emit("input_method_changed", self._input_controller:get_input_method())
    self:create_from_state(self._state)
    self._is_realized = true
end

--- @override
function mn.KeybindingScene:create_from_state(state)
    for item_row in values(self._items) do
        for item in values(item_row) do
            local keyboard, gamepad = self._state:get_keybinding(item.button)
            item.gamepad_indicator:create_from_gamepad_button(gamepad)
            item.gamepad_binding = gamepad
            item.keyboard_indicator:create_from_keyboard_key(keyboard)
            item.keyboard_binding = keyboard
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
    local n_rows = 0
    for item_row in values(self._items) do
        local row_n = 0
        for item in values(item_row) do
            local label_w, label_h = item.label:measure()
            max_label_w = math.max(max_label_w, label_w)
            row_n = row_n + 1
        end
        max_row_n = math.max(max_row_n, row_n)
        n_rows = n_rows + 1
    end

    max_label_w = math.max(max_label_w, select(1, self._accept_label:measure()))
    max_label_w = math.max(max_label_w, select(1, self._go_back_label:measure()))

    local indicator_w = 6.5 * m
    local indicator_h = indicator_w
    local item_w = xm + max_label_w + 2 * xm + indicator_w + xm
    local item_h = math.max(max_label_h, indicator_h) + 2 * ym
    local item_xm = m
    local item_ym = m
    current_x = x + 0.5 * width - (max_row_n * item_w + (max_row_n - 1) * item_xm) / 2
    item_x = current_x

    --current_y = y + 0.5 * height - (n_rows * item_h + (n_rows - 1) * item_ym) / 2
    --item_y = current_y

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

    self._confirm_load_default_dialog:fit_into(x, y, width, height)
    self._confirm_abort_dialog:fit_into(x, y, width, height)
    self._keybinding_invalid_dialog:fit_into(x, y, width, height)
    self:_regenerate_selection_nodes()

    self:_update_snapshots()
end

--- @brief
function mn.KeybindingScene:_update_snapshots()

    for snapshot in values(self._snapshots) do
        snapshot:free()
    end

    self._snapshots = {
        rt.RenderTexture(self._bounds.width, self._bounds.height, self._state:get_msaa_quality())
    }

    self._snapshots[1]:bind()

    local function draw_frame(frame)
        local before = frame:get_selection_state()
        frame:set_selection_state(rt.SelectionState.INACTIVE)
        frame:draw()
        frame:set_selection_state(before)
    end

    for frame in range(
        self._heading_frame,
        self._go_back_frame,
        self._accept_frame,
        self._restore_defaults_frame
    ) do
        draw_frame(frame)
    end

    self._heading_label:draw()
    self._control_indicator:draw()

    local keyboard_or_gamepad = self._input_controller:get_input_method() == rt.InputMethod.KEYBOARD
    for item_row in values(self._items) do
        for item in values(item_row) do
            draw_frame(item.frame)
            item.label:draw()
        end
    end

    self._go_back_label:draw()
    self._accept_label:draw()
    self._restore_defaults_label:draw()

    self._snapshots[1]:unbind()
end

--- @brief
function mn.KeybindingScene:_regenerate_selection_nodes()
    self._selection_graph:clear()

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
                scene._active_frame = self.item.frame
                scene._active_label = self.item.label
            end)

            node:signal_connect("exit", function(self)
                self.item.frame:set_selection_state(rt.SelectionState.INACTIVE)
                scene._active_frame = nil
                scene._active_label = nil
            end)

            node:signal_connect(rt.InputButton.A, function(self)
                scene:_start_assignment(self.item.button)
            end)
        end
    end

    local accept_node = rt.SelectionGraphNode(self._accept_frame:get_bounds())
    local abort_node = rt.SelectionGraphNode(self._go_back_frame:get_bounds())
    local restore_defaults_node = rt.SelectionGraphNode(self._restore_defaults_frame:get_bounds())
    self._selection_graph:add(accept_node, abort_node, restore_defaults_node)

    local bottom_nodes = {}
    for node_frame_label in range(
        {accept_node, self._accept_frame, self._accept_label},
        {abort_node, self._go_back_frame, self._go_back_label},
        {restore_defaults_node, self._restore_defaults_frame, self._restore_defaults_label}
    ) do
        local node, frame, label = table.unpack(node_frame_label)

        node:signal_connect("enter", function(_)
            frame:set_selection_state(rt.SelectionState.ACTIVE)
            scene._active_frame = frame
            scene._active_label = label
        end)

        node:signal_connect("exit", function(_)
            frame:set_selection_state(rt.SelectionState.INACTIVE)
            scene._active_frame = nil
            scene._active_label = nil
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

    accept_node:signal_connect(rt.InputButton.A, function(_)
        scene:_accept()
    end)

    abort_node:signal_connect(rt.InputButton.A, function(_)
        scene:_abort()
    end)

    restore_defaults_node:signal_connect(rt.InputButton.A, function(_)
        scene:_restore_defaults()
    end)

    self._selection_graph:set_current_node(item_rows[1][1])
    self._accept_node = accept_node
end

--- @override
function mn.KeybindingScene:update(delta)
    self._skip_frame = self._skip_frame - 1

    self._confirm_load_default_dialog:update(delta)
    self._confirm_abort_dialog:update(delta)
    self._keybinding_invalid_dialog:update(delta)
end

--- @brief
function mn.KeybindingScene:_start_assignment(button)
    meta.assert_enum_value(button, rt.InputButton)
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
        item.keyboard_indicator:create_from_keyboard_key(which)
        item.keyboard_binding = which
    else
        item.gamepad_indicator:create_from_gamepad_button(which)
        item.gamepad_binding = which
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

    for snapshot in values(self._snapshots) do
        snapshot:draw()
    end

    if self._active_frame ~= nil then
        self._active_frame:draw()
    end

    if self._active_label ~= nil then
        self._active_label:draw()
    end

    local keyboard_or_gamepad = self._input_controller:get_input_method() == rt.InputMethod.KEYBOARD
    for item_row in values(self._items) do
        for item in values(item_row) do
            if keyboard_or_gamepad then
                item.keyboard_indicator:draw()
            else
                item.gamepad_indicator:draw()
            end
        end
    end

    if self._confirm_load_default_dialog:get_is_active() then
        self._confirm_load_default_dialog:draw()
    end

    if self._confirm_abort_dialog:get_is_active() then
        self._confirm_abort_dialog:draw()
    end

    if self._keybinding_invalid_dialog:get_is_active() then
        self._keybinding_invalid_dialog:draw()
    end
end

--- @override
function mn.KeybindingScene:make_active()
    if not self._is_realized then self:realize() end
    self._is_active = true
    self._selection_graph:set_current_node(self._accept_node)
    self:_update_snapshots()
    self._input_controller:signal_unblock_all()
end

--- @override
function mn.KeybindingScene:make_inactive()
    self._is_active = false
    self._snapshots = {}
    self._input_controller:signal_block_all()
end

--- @brief
function mn.KeybindingScene:_restore_defaults()
    self._confirm_load_default_dialog:present()
end

--- @brief
function mn.KeybindingScene:_abort()
    for item_row in values(self._items) do
        for item in values(item_row) do
            local current_key, current_pad = self._state:get_keybinding(item.button)
            local item_key, item_pad = item.keyboard_binding, item.gamepad_binding
            if current_key ~= item_key or current_pad ~= item_pad then
                self._confirm_abort_dialog:present()
                return
            end
        end
    end
    self:_exit_scene()
end

--- @brief
function mn.KeybindingScene:_accept()
    local new_mapping = {}
    local n_pairs = 0
    for item_row in values(self._items) do
        for item in values(item_row) do
            new_mapping[item.button] = {
                keyboard = item.keyboard_binding,
                gamepad = item.gamepad_binding
            }
            n_pairs = n_pairs + 1
        end
    end

    local is_valid, message = rt.InputControllerState:validate_input_mapping(new_mapping)

    if is_valid then
        local pair_i = 1
        for button, binding in pairs(new_mapping) do
            self._state:set_keybinding(button, binding.keyboard, binding.gamepad, pair_i >= n_pairs) -- only notify on last
            pair_i = pair_i + 1
        end
        self:_exit_scene()
    else
        self._keybinding_invalid_dialog:set_submessage(message)
        self._keybinding_invalid_dialog:present()
    end
end

--- @brief
function mn.KeybindingScene:_exit_scene()
    self._state:set_current_scene(mn.OptionsScene)
end