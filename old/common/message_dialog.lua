
rt.settings.message_dialog = {
    input_delay = 0.2, -- seconds
    shadow_strength = 0.2, -- factor for Blendmode.MULTIPLY
}

rt.MessageDialogOption = meta.new_enum({
    ACCEPT = "OK",
    CANCEL = "Cancel"
})

--- @class rt.MessageDialog
--- @param message String
--- @param submessage String
--- @param option1 vararg
--- @signal selection (rt.MessageDialog, Unsigned) -> nil
rt.MessageDialog = meta.new_type("MessageDialog", rt.Widget, rt.SignalEmitter, function(message, submessage, option1, ...)
    local out = meta.new(rt.MessageDialog, {
        _message = message,
        _submessage = submessage,
        _options = {option1, ...},

        _selected_item_i = 1,

        _message_label = {}, -- rt.Label
        _submessage_label = {}, -- rt.Label
        _buttons = {},
        _frame = rt.Frame(),

        _render_x_offset = 0,
        _render_y_offset = 0,

        _is_active = false,
        _input = rt.InputController(),

        _elapsed = 0
    })

    for i, option in ipairs(out._options) do
        meta.assert_string(option)
        if option == rt.MessageDialogOption.CANCEL then
            out._selected_item_i = i
        end
    end

    out:signal_add("selection")
    return out
end)

--- @brief
function rt.MessageDialog:set_is_active(b)
    self._is_active = b
    self._input:set_is_disabled(not b)
end

--- @brief
function rt.MessageDialog:get_is_active()
    return self._is_active
end

--- @brief
function rt.MessageDialog:close()
    self:set_is_active(false)
    self:set_is_visible(false)
end

--- @brief
function rt.MessageDialog:present()
    self._elapsed = 0
    self:set_is_active(true)
    self:set_is_visible(true)
end

--- @override
function rt.MessageDialog:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:realize()

    self._message_label = rt.Label("<b>" .. self._message .. "</b>", rt.settings.font.default, rt.settings.font.default_mono)
    self._submessage_label = rt.Label(self._submessage, rt.settings.font.default_small, rt.settings.font.default_mono_small)

    for label in range(self._message_label, self._submessage_label) do
        label:set_justify_mode(rt.JustifyMode.CENTER)
        label:realize()
    end

    self._buttons = {}
    for option in values(self._options) do
        local to_insert = {
            label = rt.Label(option),
            frame = rt.Frame()
        }

        to_insert.frame:realize()
        to_insert.frame:set_color(rt.Palette.GRAY_3)
        to_insert.label:realize()
        to_insert.label:set_justify_mode(rt.JustifyMode.CENTER)

        table.insert(self._buttons, to_insert)
    end

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)
end

--- @override
function rt.MessageDialog:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit

    local max_w = NEGATIVE_INFINITY
    local max_h = NEGATIVE_INFINITY
    for item in values(self._buttons) do
        local label_w, label_h = item.label:measure()
        max_w = math.max(max_w, label_w)
        max_h = math.max(max_h, label_h)
    end

    local n_buttons = sizeof(self._buttons)
    local title_label_w, title_label_h = self._message_label:measure()
    max_w = math.max(max_w, title_label_w / n_buttons)
    max_w = math.max(max_w, rt.graphics.get_width() / 4 / n_buttons)

    local item_w = max_w + 4 * m
    local item_h = max_h + 1.5 * m

    local button_w = n_buttons * item_w + (n_buttons - 1) * m

    self._message_label:fit_into(0, 0, button_w)
    self._submessage_label:fit_into(0, 0, button_w)

    local sub_label_w, sub_label_h = self._submessage_label:measure()

    local xm, ym = 4 * m, 2 * m
    local start_x, start_y = xm, ym
    local current_x, current_y = start_x, start_y
    self._message_label:fit_into(current_x, current_y, button_w, title_label_h)
    current_y = current_y + title_label_h
    self._submessage_label:fit_into(current_x, current_y, button_w, sub_label_h)
    current_y = current_y + sub_label_h + m

    for item in values(self._buttons) do
        local label_h = select(2, item.label:measure())
        item.label:fit_into(current_x, current_y + 0.5 * item_h - 0.5 * label_h, item_w, item_h)
        item.frame:fit_into(current_x, current_y, item_w, item_h)
        current_x = current_x + item_w + m
    end

    current_y = current_y + item_h

    local frame_w, frame_h = button_w + 2 * xm, current_y - start_y + 2 * ym
    self._frame:fit_into(start_x - xm, start_y - ym, frame_w, frame_h)

    self._render_x_offset = math.floor(x + 0.5 * width - 0.5 * frame_w)
    self._render_y_offset = math.floor(y + 0.5 * height - 0.5 * frame_h)

    self:_update_selected_item()
end

--- @override
function rt.MessageDialog:draw()
    if self:get_is_visible() == false then return end

    rt.graphics.translate(self._render_x_offset, self._render_y_offset)

    self._frame:draw()
    self._message_label:draw()
    self._submessage_label:draw()

    for item_i, item in ipairs(self._buttons) do
        item.frame:draw()
        item.label:draw()
    end

    rt.graphics.translate(-1 * self._render_x_offset, -1 * self._render_y_offset)
end

--- @brief
function rt.MessageDialog:_update_selected_item()
    for item_i, item in ipairs(self._buttons) do
        if item_i == self._selected_item_i then
            item.frame:set_selection_state(rt.SelectionState.ACTIVE)
        else
            item.frame:set_selection_state(rt.SelectionState.INACTIVE)
        end
    end
end

--- @brief
function rt.MessageDialog:_handle_button_pressed(which)
    if self._elapsed < rt.settings.message_dialog.input_delay then
        return
    end

    if which == rt.InputButton.LEFT then
        if self._selected_item_i > 1 then
            self._selected_item_i = self._selected_item_i - 1
            self:_update_selected_item()
        end
    elseif which == rt.InputButton.RIGHT then
        if self._selected_item_i < sizeof(self._buttons) then
            self._selected_item_i = self._selected_item_i + 1
            self:_update_selected_item()
        end
    elseif which == rt.InputButton.A then
        self:signal_emit("selection", self._options[self._selected_item_i])
    end
end

--- @override
function rt.MessageDialog:update(delta)
    if self._is_active then
        self._elapsed = self._elapsed + delta
    end
end