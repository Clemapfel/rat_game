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

        _input_controller = rt.InputController()
    })
end)

rt.ControlIndicatorButton = meta.new_enum("ControlIndicatorButton", {
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
            local up, _ = rt.get_active_state():get_keybinding(rt.InputButton.UP)
            local down, _ = rt.get_active_state():get_keybinding(rt.InputButton.DOWN)
            indicator:create_as_two_vertical_keys(
                rt.keyboard_key_to_string(up),
                rt.keyboard_key_to_string(down)
            )
        elseif button == rt.ControlIndicatorButton.LEFT_RIGHT then
            local left, _ = rt.get_active_state():get_keybinding(rt.InputButton.LEFT)
            local right, _ = rt.get_active_state():get_keybinding(rt.InputButton.RIGHT)
            indicator:create_as_two_horizontal_keys(
                rt.keyboard_key_to_string(left),
                rt.keyboard_key_to_string(right)
            )
        elseif button == rt.ControlIndicatorButton.ALL_DIRECTIONS then
            local up, _ = rt.get_active_state():get_keybinding(rt.InputButton.UP)
            local down, _ = rt.get_active_state():get_keybinding(rt.InputButton.DOWN)
            local left, _ = rt.get_active_state():get_keybinding(rt.InputButton.LEFT)
            local right, _ = rt.get_active_state():get_keybinding(rt.InputButton.RIGHT)
            indicator:create_as_four_keys(
                rt.keyboard_key_to_string(up),
                rt.keyboard_key_to_string(right),
                rt.keyboard_key_to_string(down),
                rt.keyboard_key_to_string(left)
            )
        else
            local binding, _ = rt.get_active_state():get_keybinding(button)
            indicator:create_from_keyboard_key(binding)
        end
    else
        if button == rt.ControlIndicatorButton.UP_DOWN then
            indicator:create_as_dpad(true, false, true, false)
        elseif button == rt.ControlIndicatorButton.LEFT_RIGHT then
            indicator:create_as_dpad(false, true, false, true)
        elseif button == rt.ControlIndicatorButton.ALL_DIRECTIONS then
            indicator:create_as_dpad(false, false, false, false)
        else
            local _, binding = rt.get_active_state():get_keybinding(button)
            indicator:create_from_gamepad_button(binding)
        end
    end
end

--- @override
function rt.ControlIndicator:realize()
    if self:already_realized() then return end

    self._frame:realize()
    self:create_from(self._layout)

    self._input_controller:signal_connect("input_mapping_changed", function(_)
        self:create_from(self._layout)
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
    local indicator_width = 12 * m

    local xm = 2 * m
    local ym = 0.0 * m
    height = indicator_width + 2 * ym

    local current_x, current_y = x + 4 * m, y + ym
    for i = 1, #self._labels do
        local keyboard_indicator, gamepad_indicator, label = self._keyboard_indicators[i], self._gamepad_indicators[i], self._labels[i]

        for indicator in range(keyboard_indicator, gamepad_indicator) do
            indicator:fit_into(current_x, 0 + 0.5 * height - 0.5 * indicator_width , indicator_width, indicator_width)
        end

        current_x = current_x + indicator_width + 2 * m
        local label_w, label_h = label:measure()
        label:fit_into(current_x, 0 + 0.5 * height - 0.5 * label_h, POSITIVE_INFINITY)

        current_x = current_x + label_w + 4 * m
    end

    local thickness = self._frame:get_thickness()
    self._final_height = height
    self._final_width = current_x - x
    self._frame:fit_into(0, 0, self._final_width, self._final_height)
end

--- @override
function rt.ControlIndicator:draw()
    if #self._layout == 0 then return end

    local x_offset, y_offset = self._bounds.x, self._bounds.y
    rt.graphics.translate(x_offset, y_offset)

    local use_keyboard = self._input_controller:get_input_method() == rt.InputMethod.KEYBOARD
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
    end
end