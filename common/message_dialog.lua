--- @class rt.MessageDialog
rt.MessageDialog = meta.new_type("MessageDialog", rt.Widget, function(message, submessage, option1, ...)
    local out = meta.new(rt.MessageDialog, {
        _message = message,
        _submessage = submessage,
        _options = {option1, ...},

        _selected_item_i = 1,

        _message_label = {}, -- rt.Label
        _submessage_label = {}, -- rt.Label
        _buttons = {},
        _frame = rt.Frame(),
        _shadow = rt.Rectangle(0, 0, 1, 1),

        _render_x_offset = 0,
        _render_y_offset = 0
    })

    meta.assert_string(out._message)
    meta.assert_string(out._submessage)
    for option in values(out._options) do
        meta.assert_string(option)
    end

    return out
end)

--- @override
function rt.MessageDialog:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local frame_color = rt.Palette.GRAY_4
    self._frame:realize()
    self._frame:set_color(frame_color)

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
            base = rt.Rectangle(0, 0, 1, 1),
            outline = rt.Rectangle(0, 0, 1, 1),
            selection_outline = rt.Rectangle(0, 0, 1, 1),
            frame = rt.Frame()
        }

        to_insert.frame:realize()
        to_insert.frame:set_color(frame_color)

        to_insert.label:realize()
        to_insert.label:set_justify_mode(rt.JustifyMode.CENTER)
        to_insert.base:set_color(rt.Palette.GRAY_5)
        to_insert.outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
        to_insert.selection_outline:set_color(rt.Palette.SELECTION)

        for rect in range(to_insert.base, to_insert.outline, to_insert.selection_outline) do
            rect:set_corner_radius(rt.settings.frame.corner_radius)
        end

        for rect in range(to_insert.outline, to_insert.selection_outline) do
            rect:set_is_outline(true)
        end

        table.insert(self._buttons, to_insert)
    end

    local factor = 0.3
    self._shadow:set_color(rt.RGBA(factor, factor, factor,  1))
end

--- @override
function rt.MessageDialog:size_allocate(x, y, width, height)
    self._shadow:resize(x, y, width, height)

    local m = rt.settings.margin_unit

    local max_w = NEGATIVE_INFINITY
    local max_h = NEGATIVE_INFINITY
    for item in values(self._buttons) do
        local label_w, label_h = item.label:measure()
        max_w = math.max(max_w, label_w)
        max_h = math.max(max_h, label_h)
    end

    local item_w = max_w + 4 * m
    local item_h = max_h + 2 * m

    local n_buttons = sizeof(self._buttons)
    local button_w = n_buttons * item_w + (n_buttons - 1) * m

    self._message_label:fit_into(0, 0, button_w)
    self._submessage_label:fit_into(0, 0, button_w)

    local title_label_w, title_label_h = self._message_label:measure()
    local sub_label_w, sub_label_h = self._submessage_label:measure()

    local xm, ym = 4 * m, 2 * m
    local start_x, start_y = xm, ym
    local current_x, current_y = start_x, start_y
    self._message_label:fit_into(current_x, current_y, button_w, title_label_h)
    current_y = current_y + title_label_h
    self._submessage_label:fit_into(current_x, current_y, button_w, sub_label_h)
    current_y = current_y + sub_label_h + m

    for item in values(self._buttons) do
        for shape in range(item.base, item.outline, item.selection_outline) do
            shape:resize(current_x, current_y, item_w, item_h)
        end

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
end

--- @override
function rt.MessageDialog:draw()
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
    self._shadow:draw()
    rt.graphics.set_blend_mode()

    rt.graphics.translate(self._render_x_offset, self._render_y_offset)

    self._frame:draw()
    self._message_label:draw()
    self._submessage_label:draw()

    for item_i, item in ipairs(self._buttons) do
        item.base:draw()
        if item_i == self._selected_item_i then
            item.selection_outline:draw()
        else
            item.outline:draw()
        end

        item.frame:draw()
        item.label:draw()
    end

    rt.graphics.translate(-1 * self._render_x_offset, -1 * self._render_y_offset)
end

