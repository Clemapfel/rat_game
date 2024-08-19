-- @class mn.KeybindingIndicator
mn.KeybindingIndicator = meta.new_type("MenuKeybindingIndicator", rt.Widget, function(state, input_button)
    local out = meta.new(mn.KeybindingIndicator, {
        _state = state,
        _button_sprite = rt.Sprite(rt.settings.control_indicator.spritesheet_id, input_button),
        _frame = rt.Frame(),
        _gamepad_button_label = rt.Label(" "),
        _keyboard_key_label = rt.Label(" "),
    })
    return out
end)

--- @override
function mn.KeybindingIndicator:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._button_sprite:realize()
    self._frame:realize()

    for label in range(self._keyboard_key_label, self._gamepad_button_label) do
        label:realize()
        label:set_justify_mode(rt.JustifyMode.RIGHT)
    end
end

--- @override
function mn.KeybindingIndicator:size_allocate(x, y, width, height)
    self._frame:fit_into(x, y, width, height)
    local sprite_scale = rt.settings.control_indicator.sprite_scale
    local sprite_w, sprite_h = self._button_sprite:get_resolution()
    sprite_w = sprite_w * sprite_scale
    sprite_h = sprite_h * sprite_scale

    local m = rt.settings.margin_unit
    self._button_sprite:fit_into(x + m, y + 0.5 * height - 0.5 * sprite_h, sprite_w, sprite_h)

    local _, label_h = self._keyboard_key_label:measure()
    local label_x, label_y, label_w = x + m, y + 0.5 * height - 0.5 * label_h, width - 4 * m
    self._keyboard_key_label:fit_into(label_x, label_y, label_w, label_h)
    self._gamepad_button_label:fit_into(label_x, label_y, label_w, label_h)
end

--- @override
function mn.KeybindingIndicator:draw()
    self._frame:draw()
    self._button_sprite:draw()
    --self._keyboard_key_label:draw()
    self._gamepad_button_label:draw()
end

--- @override
function mn.KeybindingIndicator:set_keyboard_key_label(text)
    self._keyboard_key_label:set_text(text)
end

--- @override
function mn.KeybindingIndicator:set_gamepad_button_label(text)
    self._gamepad_button_label:set_text(text)
end