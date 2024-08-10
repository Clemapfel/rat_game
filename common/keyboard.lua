rt.settings.keyboard = {
    n_ticks_per_second = 8,
    tick_delay = 0.25,        -- seconds until auto-move triggers
    underline_thickness = 3,
    underline_outline_thickness_delta = 2
}

--- @class rt.Keyboard
--- @signal accept (rt.Keyboard, String) -> nil
--- @signal cancel (rt.Keyboard) -> nil
rt.Keyboard = meta.new_type("Keyboard", rt.Widget, rt.SignalEmitter, function(max_n_entry_chars, suggestion)
    meta.assert_number(max_n_entry_chars)
    meta.assert_string(suggestion)
    local out = meta.new(rt.Keyboard, {
        _letter_frame = rt.Frame(),
        _letter_items = {}, -- Table<Table<rt.Label>>
        _character_to_item = {},
        _accept_item = nil,
        _cancel_item = nil,

        _max_n_entry_chars = max_n_entry_chars,
        _suggestion = suggestion,
        _entry_text = suggestion,
        _entry_stencil = rt.Rectangle(0, 0, 1, 1),
        _entry_x_offset = 0,
        _entry_label_frame = rt.Frame(),
        _entry_label = rt.Label("_"),
        _char_count_label = rt.Label("0"),

        _input = rt.InputController(),
        _text_input_active = false,
        _swallow_first_text_input = true,

        _input_tick_elapsed = {
            [rt.InputButton.UP] = 0,
            [rt.InputButton.RIGHT] = 0,
            [rt.InputButton.DOWN] = 0,
            [rt.InputButton.LEFT] = 0,
            [rt.InputButton.A] = 0,
            [rt.InputButton.B] = 0
        },
        _input_tick_delay = {
            [rt.InputButton.UP] = 0,
            [rt.InputButton.RIGHT] = 0,
            [rt.InputButton.DOWN] = 0,
            [rt.InputButton.LEFT] = 0,
            [rt.InputButton.A] = 0,
            [rt.InputButton.B] = 0
        },
        _selection_graph = rt.SelectionGraph(),
        _last_selected_item = nil,

        _control_indicator = rt.ControlIndicator({rt.ControlIndicatorButton.ALL_BUTTONS, ""}),

        _is_active = false,
        _x_offset = 0,
        _y_offset = 0,

        _snapshot_padding = 10,
        _snapshot_texture = rt.RenderTexture()
    })

    out:signal_add("accept")
    out:signal_add("cancel")
    return out
end)

rt.Keyboard._layout = {
    --[[
    A B C D E F G H I J     À Á Â Ä Ã È É Ê Ë Ẽ
    K L M N O P Q R S T     Ò Ó Ô Ö Õ Ù Ú Û Ü Ũ
    U V W X Y Z             Í Ï Ñ Ç ẞ

    A B C D E F G H I J
    K L M N O P Q R S T
    U V W X Y Z

    a b c d e f g h i j     à á â ä ã è é ê ë ẽ
    k l m n o p q r s t     ò ó ô ö õ ù ú û ü ũ
    u v w x y z             í ï ñ ç ß

    0 1 2 3 4 5 6 7 8 9     . , : ; ! ¡ ? ¿ ( ) + - ~ = " * # / \ < > @ _ ^ ° ' [ ] { } |


    . , : ; " ' ! ? * ^
    + - = ~ | # % $ & _
    < > ( ) [ ] { } / \

    ]]--
    --[[
    {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "", "", "À", "Á", "Â", "Ä", "Ã", "È", "É", "Ê", "Ë", "Ẽ"},
    {"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "", "", "Ò", "Ó", "Ô", "Ö", "Õ", "Ù", "Ú", "Û", "Ü", "Ũ"},
    {"U", "V", "W", "X", "Y", "Z", " ", " ", " ", " ", "", "", "Í", "Ï", "Ñ", "Ç"},
    ]]--
    {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "", "", "à", "á", "â", "ä", "ã", "è", "é", "ê", "ë", "ẽ"},
    {"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "", "", "ò", "ó", "ô", "ö", "õ", "ù", "ú", "û", "ü", "ũ"},
    {"U", "V", "W", "X", "Y", "Z", " ", " ", " ", " ", "", "", "í", "ï", "ñ", "ç", "ß", " ", " ", " ", " ", " "},
    {},
    {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "", "", ".", ",", ":", ";", "\"", "'", "!", "?", "*", "^"},
    {"k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "", "", "_", "+", "-", "=", "~", "\\|", "#", "%", "$", "&"},
    {"u", "v", "w", "x", "y", "z", " ", " ", " ", " ", "", "", "\\<", "\\>", "(", ")", "[", "]", "{", "}", "/", "\\\\"},
    {},
    {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "", "", "\u{2605}", "\u{266A}", "\u{2665}", "\u{25C6}"}
}

--- @override
function rt.Keyboard:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._letter_frame:realize()
    self._labels = {}

    local max_row_n = NEGATIVE_INFINITY
    local row_i_to_row_n = {}
    for row_i, row in ipairs(self._layout) do
        local n = sizeof(row)
        row_i_to_row_n[row_i] = row
        max_row_n = math.max(max_row_n, n)
    end

    local font, font_mono = rt.settings.font.default, rt.settings.font.default_mono

    local selection_prefix = "<b><color=SELECTION>"
    local selection_postfix = "</b></color>"

    self._letter_items = {}
    self._max_label_w = NEGATIVE_INFINITY
    self._max_label_h = NEGATIVE_INFINITY

    self._character_to_item = {}

    local function initialize_item(char)
        local item = {
            label = rt.Label("<o>" .. char .. "</o>", font, font_mono),
            selected_label = rt.Label("<o>" .. selection_prefix .. char .. selection_postfix .. "</o>", font, font_mono),
            letter = char,
            underline = rt.Line(0, 0, 1, 1),
            underline_outline = rt.Line(0, 0, 1, 1),
            is_selected = false,
            node = rt.SelectionGraphNode()
        }

        self._character_to_item[char] = item

        for label in range(item.label, item.selected_label) do
            label:set_justify_mode(rt.JustifyMode.CENTER)
            label:realize()
        end

        item.underline:set_line_width(rt.settings.keyboard.underline_thickness)
        item.underline:set_color(rt.Palette.SELECTION)
        item.underline_outline:set_line_width(rt.settings.keyboard.underline_thickness + rt.settings.keyboard.underline_outline_thickness_delta)
        item.underline_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)

        item.node.item = item

        local label_w, label_h = item.label:measure()
        self._max_label_w = math.max(label_w, self._max_label_w)
        self._max_label_h = math.max(label_h, self._max_label_h)

        return item
    end

    for row_i, row in ipairs(self._layout) do
        local to_push = {}
        for i = 1, max_row_n do
            local char = self._layout[row_i][i]
            if char == nil then
                char = ""
            end

            table.insert(to_push, initialize_item(char))
        end
        table.insert(self._letter_items, to_push)
    end

    local last_row = self._letter_items[#self._letter_items]
    self._accept_item = initialize_item("Accept")
    self._cancel_item = initialize_item("Cancel")
    last_row[#last_row] = self._accept_item
    last_row[#last_row - 1] = self._cancel_item

    do
        local label = rt.Label(" ")
        label:realize()
        self._max_label_w = select(1, label:measure())
    end

    self._entry_label_frame:realize()
    self._entry_label:realize()
    self._char_count_label:realize()
    self._char_count_label:set_justify_mode(rt.JustifyMode.RIGHT)

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)

    self._input:signal_connect("released", function(_, which)
        self:_handle_button_released(which)
    end)

    self._input:signal_connect("text_input", function(_, text)
        self:_handle_textinput(text)
    end)

    self:_update_control_indicator();
    self._control_indicator:realize()
    self:_update_entry()
end

--- @override
function rt.Keyboard:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit

    local label_w = math.max(self._max_label_w, self._max_label_h) + m
    local label_h = label_w
    local label_xm, label_ym = 0 * label_w, 0.5 * m
    local letter_xm, letter_ym = 2 * m, 2 * m

    local max_row_n = NEGATIVE_INFINITY
    for row in values(self._layout) do
        max_row_n = math.max(max_row_n, #row)
    end

    self._selection_graph:clear()
    local keyboard = self

    local line_w, line_h
    do
        local label = rt.Label("#")
        label:realize()
        line_w = select(1, label:measure())
    end
    line_h = rt.settings.keyboard.underline_thickness

    local outline_line_w = line_w + rt.settings.keyboard.underline_outline_thickness_delta

    local current_x, current_y = x, y

    local total_w = max_row_n * label_w + (max_row_n - 1) * label_xm + 2 * letter_xm
    local indicator_w, indicator_h = self._control_indicator:measure()

    local entry_label_w, entry_label_h = self._entry_label:measure()

    local top_row_h = indicator_h
    self._control_indicator:fit_into(
        current_x + total_w - indicator_w,
        current_y,
        indicator_w,
        indicator_h
    )

    local frame_aabb = rt.AABB(current_x, current_y, total_w - indicator_w, top_row_h)
    self._entry_label_frame:fit_into(frame_aabb)
    local entry_w, entry_h = self._entry_label:measure()
    self._entry_label:fit_into(frame_aabb.x + letter_xm, frame_aabb.y + 0.5 * frame_aabb.height - 0.5 * entry_h, POSITIVE_INFINITY)
    self:_update_entry()

    current_y = y + top_row_h

    local start_x, start_y = current_x + letter_xm, current_y + letter_ym
    current_x, current_y = start_x, start_y

    local special_item_up_candidates = {}
    self._selection_graph:clear()

    local n_rows = sizeof(self._letter_items)
    for row_i, row in ipairs(self._letter_items) do
        local n_items = sizeof(row)
        for item_i, item in ipairs(row) do
            if item.letter ~= "" then
                item.node:signal_disconnect_all()

                local frame_aabb = rt.AABB(current_x, current_y, label_w, label_h)
                local current_label_w, current_label_h = item.label:measure()
                local label_bounds = rt.AABB(current_x, current_y + 0.5 * label_h - 0.5 * current_label_h, label_w, label_w)
                item.label:fit_into(label_bounds)
                item.selected_label:fit_into(label_bounds)

                item.underline:resize(
                    current_x + 0.5 * label_w - 0.5 * line_w,
                    current_y + label_h - line_h,
                    current_x + 0.5 * label_w + 0.5 * line_w,
                    current_y + label_h - line_h
                )

                item.underline_outline:resize(
                    current_x + 0.5 * label_w - 0.5 * outline_line_w,
                    current_y + label_h - line_h,
                    current_x + 0.5 * label_w + 0.5 * outline_line_w,
                    current_y + label_h - line_h
                )

                item.node:set_bounds(frame_aabb)

                self._selection_graph:add(item.node)

                -- link nodes, skipping "" while keeping them for layout
                do
                    local previous_i = ternary(item_i == 1, max_row_n, item_i - 1)
                    while previous_i > 1 and row[previous_i].letter == ""  do
                        previous_i = previous_i - 1
                    end

                    if row[previous_i] ~= nil then
                        item.node:set_left(row[previous_i].node)
                    end
                end

                do
                    local next_i = ternary(item_i == n_items, 1, item_i + 1)
                    while next_i < max_row_n and row[next_i].letter == "" do
                        next_i = next_i + 1
                    end

                    if row[next_i] ~= nil then
                        item.node:set_right(row[next_i].node)
                    end
                end

                do
                    local up_i = ternary(row_i == 1, n_rows, row_i - 1)
                    while self._letter_items[up_i][item_i].letter == "" do
                        up_i = up_i - 1
                        if up_i < 1 then up_i = n_rows end
                        if self._letter_items[up_i][item_i] == item then break end
                    end

                    if self._letter_items[up_i] ~= nil and self._letter_items[up_i][item_i] ~= nil then
                        item.node:set_up(self._letter_items[up_i][item_i].node)
                    end
                end

                do
                    local down_i = ternary(row_i == n_rows, 1, row_i + 1)
                    while down_i < n_rows and self._letter_items[down_i][item_i].letter == "" do
                        down_i = down_i + 1
                    end

                    if self._letter_items[down_i] ~= nil and self._letter_items[down_i][item_i] ~= nil then
                        local down_item = self._letter_items[down_i][item_i]
                        if down_item.letter == "" or down_item == self._accept_item or down_item == self._cancel_item then
                            table.insert(special_item_up_candidates, item)
                        else
                            item.node:set_down(self._letter_items[down_i][item_i].node)
                        end
                    end
                end

                if item ~= self._accept_item and item ~= self._cancel_item then
                    item.node:signal_connect(rt.InputButton.A, function(self)
                        keyboard:_append_char(self.item.letter)
                    end)
                elseif item == self._accept_item then
                    item.node:signal_connect(rt.InputButton.A, function(self)
                        keyboard:_accept()
                    end)
                elseif item == self._cancel_item then
                    item.node:signal_connect(rt.InputButton.A, function(self)
                        keyboard:_cancel()
                    end)
                end

                item.node:signal_connect(rt.InputButton.B, function(self)
                    keyboard:_erase_char()
                end)

                item.node:signal_connect("enter", function(self)
                    self.item.is_selected = true
                end)

                item.node:signal_connect("exit", function(self)
                    self.item.is_selected = false
                    keyboard._last_selected_item = self
                end)
            end
            current_x = current_x + label_w + label_xm
        end

        current_y = current_y + label_h + label_ym
        current_x = start_x

        max_row_n = math.max(max_row_n, n_items)
    end

    -- align special items
    current_x = start_x + total_w - letter_xm - letter_xm
    current_y = current_y - label_h - label_ym

    for item in range(self._accept_item, self._cancel_item) do
        item.label:set_justify_mode(rt.JustifyMode.LEFT)
        item.selected_label:set_justify_mode(rt.JustifyMode.LEFT)

        local w, h = item.selected_label:measure()
        current_x = current_x - w
        local bounds = rt.AABB(current_x, current_y + 0.5 * label_h - 0.5 * h)
        item.label:fit_into(bounds)
        item.selected_label:fit_into(bounds)
        item.node:set_bounds(bounds)

        local line_w = 1 * w
        item.underline:resize(
            current_x + 0.5 * w - 0.5 * line_w,
            current_y + label_h - line_h,
            current_x + 0.5 * w + 0.5 * line_w,
            current_y + label_h - line_h
        )

        item.underline_outline:resize(
            current_x + 0.5 * w - 0.5 * outline_line_w,
            current_y + label_h - line_h,
            current_x + 0.5 * w + 0.5 * outline_line_w,
            current_y + label_h - line_h
        )

        current_x = current_x - letter_xm
    end

    local special_item_memory_candidates = {
        [self._accept_item] = {},
        [self._cancel_item] = {}
    }

    for candidate in values(special_item_up_candidates) do
        local best_item
        local min_distance = POSITIVE_INFINITY
        for item in range(self._accept_item, self._cancel_item) do
            local dist = math.abs(candidate.node:get_bounds().x - item.node:get_bounds().x)
            if dist < min_distance then
                min_distance = dist
                best_item = item
            end
        end

        table.insert(special_item_memory_candidates[best_item], candidate.node)
        candidate.node:set_down(best_item.node)
    end

    local min_dist = POSITIVE_INFINITY
    for item in range(self._accept_item, self._cancel_item) do
        local best_candidate = nil
        local bounds = item.node:get_bounds()
        for candidate in values(special_item_up_candidates) do
            local aabb = candidate.node:get_bounds()
            local dist = math.abs(aabb.x - (bounds.x + 0.5 * bounds.width))
            if dist < min_dist then
                min_dist = dist
                best_candidate = candidate
            end
        end

        item.node:signal_connect(rt.InputButton.UP, function(self)
            for candidate in values(special_item_memory_candidates[item]) do
                if candidate == keyboard._last_selected_item then
                    return candidate
                end
            end
            return best_candidate.node
        end)
    end

    local frame_bounds = rt.AABB(
        start_x - letter_xm,
        start_y - letter_ym,
        total_w,
        n_rows * label_h + (n_rows - 1) * label_ym + 2 * letter_ym
    )
    self._letter_frame:fit_into(frame_bounds)

    local to_select = self._letter_items[1][1]
    self._selection_graph:set_current_node(to_select.node)
    to_select.is_selected = true

    local final_w = self._control_indicator:get_bounds().x + self._control_indicator:get_bounds().width - self._entry_label_frame:get_bounds().x
    local final_h = self._letter_frame:get_bounds().y + self._letter_frame:get_bounds().height - self._control_indicator:get_bounds().y
    self._x_offset = math.floor((width - final_w) / 2)
    self._y_offset = math.floor((height - final_h) / 2)

    local padding = self._snapshot_padding
    self._snapshot_texture = rt.RenderTexture(final_w + 2 * padding, final_h + 2 * padding)
    self._snapshot_texture:bind_as_render_target()
    rt.graphics.translate(padding, padding)
    self._entry_label_frame:draw()
    self._letter_frame:draw()
    for row in values(self._letter_items) do
        for item in values(row) do
            item.label:draw()
        end
    end
    self._control_indicator:draw()
    rt.graphics.translate(-padding, -padding)
    self._snapshot_texture:unbind_as_render_target()
end

--- @override
function rt.Keyboard:draw()
    rt.graphics.translate(self._x_offset, self._y_offset)

    --[[
    local padding = self._snapshot_padding
    rt.graphics.translate(-padding, -padding)
    self._snapshot_texture:draw()
    rt.graphics.translate(padding, padding)

    self._entry_label:draw()
    self._char_count_label:draw()

    local item = self._selection_graph:get_current_node().item
    item.underline_outline:draw()
    item.underline:draw()
    item.selected_label:draw()
    ]]--

    self._entry_label_frame:draw()

    local stencil_value = meta.hash(self) % 255
    rt.graphics.stencil(stencil_value, self._entry_stencil)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)
    rt.graphics.translate(-self._entry_x_offset, 0)
    self._entry_label:draw()
    rt.graphics.translate(self._entry_x_offset, 0)
    rt.graphics.set_stencil_test()

    self._char_count_label:draw()

    self._letter_frame:draw()
    for row in values(self._letter_items) do
        for item in values(row) do
            if item.is_selected then
                item.underline_outline:draw()
                item.underline:draw()
                item.selected_label:draw()
            else
                item.label:draw()
            end
        end
    end

    self._control_indicator:draw()
    --self._selection_graph:draw()

    rt.graphics.translate(-self._x_offset, -self._y_offset)
end

--- @brief
function rt.Keyboard:_append_char(char)
    self._entry_text = self._entry_text .. char
    self:_update_entry()
end

--- @brief
function rt.Keyboard:_erase_char(char)
    local length = utf8.len(self._entry_text)
    if length > 0 then
        self._entry_text = utf8.sub(self._entry_text, 1, length - 1)
        self:_update_entry()
    end
end

--- @brief
function rt.Keyboard:_accept()
    if utf8.len(self._entry_text) > self._max_n_entry_chars then return end
    if utf8.len(self._entry_text) == 0 then
        self._entry_text = self._suggestion
        self:_update_entry()
    end
    self:signal_emit("accept", self._entry_text)
end

--- @brief
function rt.Keyboard:_cancel()
    self:signal_emit("cancel")
end

--- @brief
function rt.Keyboard:_handle_button_pressed(which)
    if self._is_active ~= true then return end

    if self._text_input_active == true then return end

    if which == rt.InputButton.START then
        self._selection_graph:set_current_node(self._accept_item.node)
    elseif which == rt.InputButton.X then
        self._selection_graph:set_current_node(self._cancel_item.node)
    else
        self._selection_graph:handle_button(which)
    end
    -- enter/exit sets selection
end

--- @brief
function rt.Keyboard:_handle_textinput(which)
    if self._is_active ~= true then return end
    if self._text_input_active == false then return end
    if self._swallow_first_text_input == true then
        self._swallow_first_text_input = false
        return
    end
    local item = self._character_to_item[which]
    if item ~= nil then
        self._selection_graph:set_current_node(item.node)
        self._selection_graph:handle_button(rt.InputButton.A)
    end
end

--- @brief
function rt.Keyboard:_handle_button_released(which)
    if self._is_active ~= true then return end
    if self._input_tick_elapsed[which] ~= nil then
        self._input_tick_elapsed[which] = 0
        self._input_tick_delay[which] = 0
    end
end

--- @brief
function rt.Keyboard:update(delta)
    local duration = 1 / rt.settings.keyboard.n_ticks_per_second
    local min_delay = rt.settings.keyboard.tick_delay
    for button in keys(self._input_tick_elapsed) do
        if self._input:is_down(button) then
            local delay = self._input_tick_delay[button]
            delay = delay + delta
            self._input_tick_delay[button] = delay

            if delay >= min_delay then
                local current = self._input_tick_elapsed[button]
                self._input_tick_elapsed[button] = current + delta

                while self._input_tick_elapsed[button] >= duration do
                    self._input_tick_elapsed[button] = self._input_tick_elapsed[button] - duration
                    self:_handle_button_pressed(button)
                end
            end
        end
    end
end

--- @brief
function rt.Keyboard:_update_entry()
    local xm = 2 * rt.settings.margin_unit
    local frame_bounds = self._entry_label_frame:get_bounds()

    local entry_str = self._entry_text
    self._entry_label:set_text(entry_str)
    local entry_w, entry_h = self._entry_label:measure()
    self._entry_label:fit_into(frame_bounds.x + xm, frame_bounds.y + 0.5 * frame_bounds.height - 0.5 * entry_h, POSITIVE_INFINITY)

    local count_str
    if utf8.len(self._entry_text) > self._max_n_entry_chars then
        count_str = "<mono><color=RED><b>" ..  (self._max_n_entry_chars - utf8.len(self._entry_text)) .. "</b></color></mono>"
        self._accept_item.label:set_opacity(0.3)
        self._accept_item.selected_label:set_opacity(0.3)
        self._accept_item.underline:set_opacity(0.3)
    else
        count_str = "<mono><color=GRAY_4>" ..  (self._max_n_entry_chars - utf8.len(self._entry_text)) .. "</color></mono>"
        self._accept_item.label:set_opacity(1)
        self._accept_item.selected_label:set_opacity(1)
        self._accept_item.underline:set_opacity(1)
    end
    self._char_count_label:set_text(count_str)
    local count_w, count_h = self._char_count_label:measure()
    self._char_count_label:fit_into(frame_bounds.x, frame_bounds.y + 0.5 * frame_bounds.height - 0.5 * count_h, frame_bounds.width - xm)

    local stencil_w = frame_bounds.width - 2 * xm - select(1, self._char_count_label:measure()) - rt.settings.margin_unit
    self._entry_stencil:resize(frame_bounds.x + xm, frame_bounds.y, stencil_w, frame_bounds.height)
    self._entry_x_offset = clamp(select(1, self._entry_label:measure()) - stencil_w, 0)
end

--- @brief
function rt.Keyboard:_update_control_indicator()
    if self._text_input_active == true then
        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.SELECT, "Disable Keyboard Input"},
        })
    else
        self._control_indicator:create_from({
            {rt.ControlIndicatorButton.B, "Erase"},
            {rt.ControlIndicatorButton.X, "Cancel"},
            {rt.ControlIndicatorButton.START, "Accept"},
            --{rt.ControlIndicatorButton.SELECT, "Enable Keyboard Input"},
        })
    end
end

--- @brief
function rt.Keyboard:set_text(text)
    self._entry_text = text
    self:_update_entry()
end

--- @brief
function rt.Keyboard:get_text()
    return self._entry_text
end

--- @brief
function rt.Keyboard:present()
    self._is_active = true
end

--- @brief
function rt.Keyboard:close()
    self._is_active = false
end

--- @brief
function rt.Keyboard:get_is_active()
    return self._is_active
end