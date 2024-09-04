--- @class rt.ControlIndicator
rt.ControlIndicator = meta.new_type("ControlIndicator", rt.Widget, function(layout)
    return meta.new(rt.ControlIndicator, {
        _layout = which(layout, {}),
        _keyboard_indicators = {},  -- Table<rt.KeybindingsIndicator>
        _gamepad_indicators = {},   -- Table<rt.KeybindingsIndicator>
        _labels = {},               -- Table<rt.Label>
        _frame = rt.Frame(),
        _opacity = 1,
        _final_width = 1,
        _final_height = 1,

        _snapshot = rt.RenderTexture(1, 1),
        _snapshot_offset_x = 0,
        _snapshot_offset_y = 0,

        _input_controller = rt.InputController()
    })
end)

rt.ControlIndicatorButton = meta.new_enum({
    A = rt.InputButton.A,
    B = rt.InputButton.B,
    X = rt.InputButton.X,
    Y = rt.InputButton.Y,
    UP = rt.InputButton.UP,
    RIGHT = rt.InputButton.RIGHT,
    DOWN = rt.InputButton.DOWN,
    LEFT = rt.InputButton.LEFT,
    START = rt.InputButton.START,
    SELECT = rt.InputButton.SELECT,
    L = rt.InputButton.L,
    R = rt.InputButton.R,
    UP_DOWN = rt.InputButton.UP .. "_" .. rt.InputButton.DOWN,
    LEFT_RIGHT = rt.InputButton.LEFT .. "_" .. rt.InputButton.RIGHT,
    ALL_DIRECTIONS = "ALL_DIRECTIONS"
})

--- @brief
function rt.ControlIndicator:_initialize_indicator_from_control_indicator_button(indicator, button, is_keyboard)
    if is_keyboard then
        if button == rt.ControlIndicatorButton.UP_DOWN then
            local up, _ = rt.InputControllerState:get_keybinding(rt.InputButton.UP)
            local down, _ = rt.InputControllerState:get_keybinding(rt.InputButton.DOWN)
            indicator:create_as_two_vertical_keys(
                rt.keyboard_key_to_string(up),
                rt.keyboard_key_to_string(down)
            )
        elseif button == rt.ControlIndicatorButton.LEFT_RIGHT then
            local left, _ = rt.InputControllerState:get_keybinding(rt.InputButton.LEFT)
            local right, _ = rt.InputControllerState:get_keybinding(rt.InputButton.RIGHT)
            indicator:create_as_two_vertical_keys(
                rt.keyboard_key_to_string(left),
                rt.keyboard_key_to_string(right)
            )
        elseif button == rt.ControlIndicatorButton.ALL_DIRECTIONS then
            local up, _ = rt.InputControllerState:get_keybinding(rt.InputButton.UP)
            local down, _ = rt.InputControllerState:get_keybinding(rt.InputButton.DOWN)
            local left, _ = rt.InputControllerState:get_keybinding(rt.InputButton.LEFT)
            local right, _ = rt.InputControllerState:get_keybinding(rt.InputButton.RIGHT)
            indicator:create_as_four_keys(
                rt.keyboard_key_to_string(up),
                rt.keyboard_key_to_string(right),
                rt.keyboard_key_to_string(down),
                rt.keyboard_key_to_string(left)
            )
        else
            local binding, _ = rt.InputControllerState:get_keybinding(button)
            indicator:create_from_keyboard_key(binding)
        end
    else
        if button == rt.ControlIndicatorButton.UP_DOWN then
            indicator:create_as_dpad(true, false, true, false)
        elseif button == rt.ControlIndicatorButton.LEFT_RIGHT then
            indicator:create_as_dpad(false, true, false, true)
        elseif button == rt.ControlIndicatorButton.ALL_DIRECTIONS then
            indicator:create_as_dpad(true, true, true, true)
        else
            local _, binding = rt.InputControllerState:get_keybinding(button)
            indicator:create_from_gamepad_button(binding)
        end
    end
end

--- @override
function rt.ControlIndicator:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:realize()
    self:create_from(self._layout)

    self._input_controller:signal_connect("input_method_changed", function(_, new)
        self:_update_snapshot()
    end)
end

--- @brief
function rt.ControlIndicator:create_from(layout)
    self._layout = layout
    self._labels = {}
    self._keyboard_indicators = {}
    self._gamepad_indicators = {}

    for pair in values(self._layout) do
        local button, text = pair[1], pair[2]
        local keyboard_indicator = rt.KeybindingIndicator()
        local gamepad_indicator = rt.KeybindingIndicator()

        self:_initialize_indicator_from_control_indicator_button(keyboard_indicator, button, true)
        self:_initialize_indicator_from_control_indicator_button(gamepad_indicator, button, false)

        for indicator in range(keyboard_indicator, gamepad_indicator) do
            indicator:realize()
        end

        table.insert(self._keyboard_indicators, keyboard_indicator)
        table.insert(self._gamepad_indicators, gamepad_indicator)

        local label = rt.Label(text, rt.settings.font.default_small, rt.settings.font.default_mono_small)
        label:realize()
        table.insert(self._labels, label)

        for widget in range(label, keyboard_indicator, gamepad_indicator) do
            widget:set_opacity(self._opacity)
        end
    end

    self:reformat()
end

--- @override
function rt.ControlIndicator:size_allocate(x, y, width, height)
    self._bounds.x, self._bounds.y = x, y
    x, y = 0, 0

    local m = rt.settings.margin_unit * 0.5

    local indicator_width = 10 * m
    local max_x, max_y = NEGATIVE_INFINITY, NEGATIVE_INFINITY
    local current_x, current_y = x + 2 * m, y + m
    for i = 1, #self._labels do
        local keyboard_indicator, gamepad_indicator, label = self._keyboard_indicators[i], self._gamepad_indicators[i], self._labels[i]

        keyboard_indicator:fit_into(current_x, current_y, indicator_width, indicator_width)
        gamepad_indicator:fit_into(current_x, current_y, indicator_width, indicator_width)

        local label_w, label_h = label:measure()
        label:fit_into(current_x + indicator_width + m, current_y + 0.5 * math.max(indicator_width, label_h) - 0.5 * math.min(indicator_width, label_h), POSITIVE_INFINITY, label_h)

        label_w, label_h = label:measure()
        max_x = math.max(max_x, current_x + indicator_width + label_w + 3 * m)
        max_y = math.max(max_y, current_y + math.max(indicator_width, label_h))

        current_x = current_x + indicator_width + m + label_w + 3 * m
    end

    max_x = clamp(max_x, 0)
    max_y = clamp(max_y, 0)

    local thickness = self._frame:get_thickness()
    self._final_width = max_x - x + 2 * thickness + m
    self._final_height = max_y - y + 2 * thickness
    self._frame:fit_into(x, y, self._final_width, self._final_height)

    self:_update_snapshot()
end

--- @brief
function rt.ControlIndicator:_update_snapshot()
    local use_keyboard = self._input_controller:get_input_method() == rt.InputMethod.KEYBOARD
    local offset = 2
    self._snapshot_offset_x, self._snapshot_offset_y = offset, offset
    self._snapshot = rt.RenderTexture(self._final_width + 2 * offset, self._final_height + 2 * offset)
    self._snapshot:bind_as_render_target()
    rt.graphics.translate(offset, offset)

    self._frame:draw()
    for i = 1, #self._labels do
        local keyboard_indicator, gamepad_indicator, label = self._keyboard_indicators[i], self._gamepad_indicators[i], self._labels[i]
        if use_keyboard then
            keyboard_indicator:draw()
        else
            gamepad_indicator:draw()
        end

        label:draw()
    end
    rt.graphics.translate(-offset, -offset)
    self._snapshot:unbind_as_render_target()
end

--- @override
function rt.ControlIndicator:draw()
    local x_offset, y_offset = self._bounds.x - self._snapshot_offset_x, self._bounds.y - self._snapshot_offset_y
    rt.graphics.translate(x_offset, y_offset)
    self._snapshot:draw()
    rt.graphics.translate(-x_offset, -y_offset)
end


--- @override
function rt.ControlIndicator:set_opacity(alpha)
    self._opacity = alpha
    for i = 1, #self._labels do
        for widget in range(self._keyboard_indicators[i], self._gamepad_indicators[i], self._labels[i]) do
            widget:set_opacity(alpha)
        end
    end
end

--- @override
function rt.ControlIndicator:measure()
    return self._final_width, self._final_height
end

--- @brief
function rt.ControlIndicator:set_selection_state(state)
    local current = self._frame:get_selection_state()
    if state ~= current then
        self._frame:set_selection_state(state)
        self:_update_snapshot()
    end
end