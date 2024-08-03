rt.settings.keyboard = {
    n_ticks_per_second = 8,
    tick_delay = 0.25,        -- seconds until auto-move triggers
    underline_thickness = 3,
    underline_outline_thickness_delta = 2
}

--- @class rt.Keyboard
--- @signal accept (rt.Keyboard, String) -> nil
--- @signal cancel (rt.Keyboard) -> nil
--- @signal dont_care (rt.Keyboard) -> String
rt.Keyboard = meta.new_type("Keyboard", rt.Widget, rt.SignalEmitter, function(max_n_entry_chars)
    meta.assert_number(max_n_entry_chars)
    return meta.new(rt.Keyboard, {
        _letter_frame = rt.Frame(),
        _letter_items = {}, -- Table<Table<rt.Label>>

        _max_n_entry_chars = max_n_entry_chars,
        _entry_label_frame = rt.Frame(),
        _entry_label = rt.Label(string.rep("_", max_n_entry_chars)),

        _input = rt.InputController(),
        _input_tick_elapsed = {
            [rt.InputButton.UP] = 0,
            [rt.InputButton.RIGHT] = 0,
            [rt.InputButton.DOWN] = 0,
            [rt.InputButton.LEFT] = 0,
        },
        _input_tick_delay = {
            [rt.InputButton.UP] = 0,
            [rt.InputButton.RIGHT] = 0,
            [rt.InputButton.DOWN] = 0,
            [rt.InputButton.LEFT] = 0,
        },
        _selection_graph = rt.SelectionGraph(),

        _control_indicator = rt.ControlIndicator({
            {rt.ControlIndicatorButton.START, "Accept"},
            {rt.ControlIndicatorButton.A, "Select"},
            {rt.ControlIndicatorButton.B, "Erase"},
            {rt.ControlIndicatorButton.X, "Abort"},
            {rt.ControlIndicatorButton.L_R, "Move Cursor"}
        })
    })
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
    {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", " ", " ", "À", "Á", "Â", "Ä", "Ã", "È", "É", "Ê", "Ë", "Ẽ"},
    {"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", " ", " ", "Ò", "Ó", "Ô", "Ö", "Õ", "Ù", "Ú", "Û", "Ü", "Ũ"},
    {"U", "V", "W", "X", "Y", "Z", " ", " ", " ", " ", " ", " ", "Í", "Ï", "Ñ", "Ç"},

    --[[
    {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", " ", " ", ".", ",", ":", ";", "\"", "'", "!", "?", "*", "^"},
    {"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", " ", " ", "+", "-", "=", "~", "\\|", "#", "%", "$", "&", "_"},
    {"U", "V", "W", "X", "Y", "Z", " ", " ", " ", " ", " ", " ", "\\<", "\\>", "(", ")", "[", "]", "{", "}", "/", "\\\\"},
    ]]--
    {},
    {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", " ", " ", "à", "á", "â", "ä", "ã", "è", "é", "ê", "ë", "ẽ"},
    {"k", "l", "m", "n", "o", "p", "q", "r", "s", "t", " ", " ", "ò", "ó", "ô", "ö", "õ", "ù", "ú", "û", "ü", "ũ"},
    {"u", "v", "w", "x", "y", "z", " ", " ", " ", " ", " ", " ", "í", "ï", "ñ", "ç", "ß"},
    {},
    {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", " ", " "}
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
    for row_i, row in ipairs(self._layout) do
        local to_push = {}
        for i = 1, max_row_n do
            local char = self._layout[row_i][i]
            if char == nil then
                char = " "
            end
            local item = {
                label = rt.Label("<o>" .. char .. "</o>", font, font_mono),
                selected_label = rt.Label("<o>" .. selection_prefix .. char .. selection_postfix .. "</o>", font, font_mono),
                letter = char,
                underline = rt.Line(0, 0, 1, 1),
                underline_outline = rt.Line(0, 0, 1, 1),
                is_selected = false,
                node = rt.SelectionGraphNode()
            }

            for label in range(item.label, item.selected_label) do
                label:set_justify_mode(rt.JustifyMode.CENTER)
                label:realize()
            end

            item.underline:set_line_width(rt.settings.keyboard.underline_thickness)
            item.underline:set_color(rt.Palette.SELECTION)
            item.underline_outline:set_line_width(rt.settings.keyboard.underline_thickness + rt.settings.keyboard.underline_outline_thickness_delta)
            item.underline_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)

            item.node.item = item
            table.insert(to_push, item)

            local label_w, label_h = item.label:measure()
            self._max_label_w = math.max(label_w, self._max_label_w)
            self._max_label_h = math.max(label_h, self._max_label_h)
        end
        table.insert(self._letter_items, to_push)
    end

    do
        local label = rt.Label(" ")
        label:realize()
        self._max_label_w = select(1, label:measure())
    end

    self._entry_label_frame:realize()
    self._entry_label:realize()

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)

    self._input:signal_connect("released", function(_, which)
        self:_handle_button_released(which)
    end)

    self._control_indicator:realize()
end

--- @override
function rt.Keyboard:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local current_x, current_y = x, y

    local entry_label_w, entry_label_h = self._entry_label:measure()
    local entry_label_xm, entry_label_ym = 2 * m, m
    self._entry_label_frame:fit_into(current_x, current_y, entry_label_w + 2 * entry_label_xm, entry_label_h + 2 * entry_label_ym)
    self._entry_label:fit_into(current_x + 2 * m, current_y + m, entry_label_w, entry_label_h)

    current_y = current_y + entry_label_h + 2 * entry_label_ym

    local label_w = math.max(self._max_label_w, self._max_label_h) + m
    local label_h = label_w
    local label_xm, label_ym = 0 * label_w, 0.5 * m

    local letter_xm, letter_ym = 4 * m, 2 * m
    local start_x, start_y = current_x + letter_xm, current_y + letter_ym
    current_x, current_y = start_x, start_y

    local max_row_n = NEGATIVE_INFINITY

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

    local n_rows = sizeof(self._letter_items)
    for row_i, row in ipairs(self._letter_items) do
        local n_items = sizeof(row)
        for item_i, item in ipairs(row) do
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

            current_x = current_x + label_w + label_xm

            item.node:set_bounds(frame_aabb)

            self._selection_graph:add(item.node)
            if item_i > 1 then
                item.node:set_left(row[item_i - 1].node)
            end

            if item_i < n_items then
                item.node:set_right(row[item_i + 1].node)
            end

            if row_i > 1 then
                item.node:set_up(self._letter_items[row_i - 1][item_i].node)
            end

            if row_i < n_rows then
                item.node:set_down(self._letter_items[row_i + 1][item_i].node)
            end

            item.node:signal_connect(rt.InputButton.A, function(self)
                keyboard:_append_char(self.item.letter)
            end)

            item.node:signal_connect("enter", function(self)
                self.item.is_selected = true
            end)

            item.node:signal_connect("exit", function(self)
                self.item.is_selected = false
            end)
        end

        current_y = current_y + label_h + label_ym
        current_x = start_x

        max_row_n = math.max(max_row_n, n_items)
    end

    local frame_bounds = rt.AABB(
        start_x - letter_xm,
        start_y - letter_ym,
        max_row_n * label_w + (max_row_n - 1) * label_xm + 2 * letter_xm,
        n_rows * label_h + (n_rows - 1) * label_ym + 2 * letter_ym
    )
    self._letter_frame:fit_into(frame_bounds)

    local to_select = self._letter_items[1][1]
    self._selection_graph:set_current_node(to_select.node)
    to_select.is_selected = true

    local indicator_w, indicator_h = self._control_indicator:measure()
    self._control_indicator:fit_into(
        frame_bounds.x,
        frame_bounds.y + frame_bounds.height,
        frame_bounds.width,
        indicator_w
    )
end

--- @override
function rt.Keyboard:draw()
    self._entry_label_frame:draw()
    self._entry_label:draw()

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
end

--- @brief
function rt.Keyboard:_append_char(char)
    println("append: `", char, "`")
end

--- @brief
function rt.Keyboard:_erase_char(char)
    println("erase")
end

--- @brief
function rt.Keyboard:_trigger_dont_care()
    println("don't care")
end

--- @brief
function rt.Keyboard:_accept()
    println("accept")
end

--- @brief
function rt.Keyboard:_cancel()
    println("cancel")
end

--- @brief
function rt.Keyboard:_handle_button_pressed(which)
    self._selection_graph:handle_button(which)
    -- enter/exit sets selection
end

--- @brief
function rt.Keyboard:_handle_button_released(which)
    if self._input_tick_elapsed[which] ~= nil then
        self._input_tick_elapsed[which] = 0
        self._input_tick_delay[which] = 0
    end
end

--- @brief
function rt.Keyboard:update(delta)
    local duration = 1 / rt.settings.keyboard.n_ticks_per_second
    local min_delay = rt.settings.keyboard.tick_delay
    for button in range(rt.InputButton.UP, rt.InputButton.RIGHT, rt.InputButton.DOWN, rt.InputButton.LEFT) do
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