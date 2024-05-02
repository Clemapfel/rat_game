rt.settings.textbox = {
    scroll_speed = 75, -- letters per second
    backdrop_opacity = 0.8,
}
rt.settings.textbox.backdrop_expand_speed = rt.settings.textbox.scroll_speed * 25 -- px per second

rt.TextBoxAlignment = meta.new_enum({
    TOP = "TOP",
    BOTTOM = "BOTTOM"
})

--- @class rt.TextBox
rt.TextBox = meta.new_type("TextBox", rt.Widget, rt.Animation, function()
    return meta.new(rt.TextBox, {
        _backdrop = {}, -- rt.Frame
        _backdrop_backing = {}, -- rt.Spacer

        _labels_aabb = rt.AABB(0, 0, 1, 1),
        _labels = {},
        _n_labels = 0,
        _total_height = 0,
        _line_height = rt.settings.font.default:get_bold_italic():getHeight(),
        _labels_stencil_mask = rt.Rectangle(0, 0, 1, 1),

        _first_visible_line = 1,
        _max_n_visible_lines = 4,
        _n_lines = 0,
        _line_i_to_label_i = {}, -- Table<Unsigned, <Unsigned, Offset>>

        _alignment = rt.TextBoxAlignment.BOTTOM,

        _continue_indicator_visible = true,
        _continue_indicator = rt.DirectionIndicator(rt.Direction.DOWN),

        _scrollbar_visible = true,
        _scrollbar = rt.Scrollbar(),
        _scroll_up_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _scroll_down_indicator = rt.DirectionIndicator(rt.Direction.DOWN),

        _backdrop_should_resize = true,
        _backdrop_current_height = 0,
        _backdrop_target_height = 100,

        _scrolling_labels = {}, -- Stack<{label, elapsed}>
        _n_scrolling_labels = 0,
    })
end)

--- @brief
function rt.TextBox:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._backdrop_backing = rt.Spacer()
    self._backdrop = rt.Frame()
    self._backdrop:set_child(self._backdrop_backing)

    self._backdrop_backing:realize()
    self._backdrop:realize()

    self._backdrop:set_opacity(rt.settings.textbox.backdrop_opacity)
    self._backdrop_backing:set_opacity(rt.settings.textbox.backdrop_opacity)

    for widget in range(
        self._continue_indicator,
        self._scroll_up_indicator,
        self._scroll_down_indicator,
        self._scrollbar
    ) do
        widget:realize()
    end

    self:set_is_animated(true)
end

--- @brief [internal]
function rt.TextBox:_backdrop_height_from_n_lines(n_lines)
    local frame_size = self._backdrop:get_thickness()
    local m = rt.settings.margin_unit
    return n_lines * self._line_height + 2 * frame_size + 2 * m
end

--- @brief [internal]
function rt.TextBox:_calculate_n_visible_lines()
    if self._first_visible_line > self._n_lines then return 0 end
    return math.min(math.min(self._first_visible_line + self._max_n_visible_lines - 1, self._n_lines) - self._first_visible_line + 1, self._n_lines)
end

--- @brief [internal]
function rt.TextBox:_get_indicator_radius()
    return self._line_height * 0.5
end

--- @brief [internal]
function rt.TextBox:_reformat_indicators()
    local frame_size = self._backdrop:get_thickness()
    local m = rt.settings.margin_unit
    local x, y, width = rt.aabb_unpack(self._bounds)
    self._backdrop:fit_into(x, y, width, self._backdrop_current_height)

    local scrollbar_margin = 5
    local scrollbar_height = self._backdrop_current_height
    local height = self:_calculate_n_visible_lines() * self._line_height
    local indicator_radius = self:_get_indicator_radius()
    local scrollbar_width = indicator_radius

    self._scrollbar:fit_into(
        x + width - frame_size - m - 0.5 * indicator_radius - 0.5 * scrollbar_width,
        self._labels_aabb.y + indicator_radius + scrollbar_margin,
        scrollbar_width, height - 2 * indicator_radius - 2 * scrollbar_margin
    )

    self._scroll_up_indicator:fit_into(
        x + width - frame_size - m - indicator_radius,
        self._labels_aabb.y,
        indicator_radius, indicator_radius
    )

    self._scroll_down_indicator:fit_into(
        x + width - frame_size - m - indicator_radius,
        self._labels_aabb.y + height - indicator_radius,
        indicator_radius, indicator_radius
    )

    self:_update_indicators()
end

--- @brief [internal]
function rt.TextBox:_update_indicators()
    local off_opacity = 0.1
    self._scroll_up_indicator:set_opacity(ternary(self:_can_scroll_up(), 1, off_opacity))
    self._scroll_down_indicator:set_opacity(ternary(self:_can_scroll_down(), 1, off_opacity))
    self._scrollbar:set_page_index(self._first_visible_line, self._n_lines - self:_calculate_n_visible_lines() + 1)
    self._scrollbar:set_is_visible(self:_calculate_n_visible_lines() < self._n_lines)
end

--- @brief
function rt.TextBox:size_allocate(x, y, width, height)
    local frame_size = self._backdrop:get_thickness()
    local m = rt.settings.margin_unit
    self._labels_aabb = rt.AABB(
        x + frame_size + m,
        y + frame_size + m,
        width - 2 * frame_size - 2 * m - self:_get_indicator_radius(),
        height - 2 * frame_size - 2 * m
    )

    self._labels_stencil_mask:resize(
        x + frame_size + m,
        y + frame_size + m,
        width - 2 * frame_size - 2 * m,
        math.min(self._max_n_visible_lines, rt.graphics.get_height()) * self._line_height
    )

    self._backdrop:fit_into(x, y, width, self._backdrop_current_height)
    self._backdrop_target_height = self:_calculate_n_visible_lines() * self._line_height + 2 * frame_size + 2 * m

    if width ~= self._labels_aabb.width then
        -- reformat everything
        self._line_i_to_label_i = {}
        local current_offset = 0
        local line_i = 1
        local label_i = 1
        for entry in values(self._labels) do
            entry.label:fit_into(0, 0, self._labels_aabb.width, POSITIVE_INFINITY)
            entry.height = select(2, entry.label:measure())
            entry.line_height = entry.label:get_line_height()
            entry.n_lines = entry.label:get_n_lines()

            for i = 1, entry.n_lines do
                self._line_i_to_label_i[line_i] = {
                    label_i = label_i,
                    offset = i - 1
                }
                line_i = line_i + 1
            end

            self._line_height = math.max(self._line_height, entry.line_height)
            label_i = label_i + 1
        end
    end

    self:_reformat_indicators()
end

--- @brief
function rt.TextBox:update(delta)
    if not self._is_realized then return end

    local frame_size = self._backdrop:get_thickness()
    local m = rt.settings.margin_unit
    self._backdrop_target_height = self:_calculate_n_visible_lines() * self._line_height + 2 * frame_size + 2 * m

    -- text scrolling
    do
        local node = table.first(self._scrolling_labels)
        if node ~= nil and node.entry.seen == true then
            node.elapsed = node.elapsed + delta
            local is_done = node.label:update_n_visible_characters_from_elapsed(node.elapsed, 10) --rt.settings.textbox.scroll_speed)
            if is_done then
                table.remove(self._scrolling_labels, 1)
                self._n_scrolling_labels = self._n_scrolling_labels - 1
            end
        end
    end

    -- text animation, only update visible labels
    local line_i = self._first_visible_line
    local n_lines_updated = 0
    local already_updated = {}
    while n_lines_updated < (self._max_n_visible_lines + 1) and line_i <= self._n_lines do  -- +1, sic
        local label_i_entry = self._line_i_to_label_i[line_i]
        if label_i_entry == nil then break end
        local label_entry = self._labels[label_i_entry.label_i]

        if already_updated[label_i_entry.label_i] ~= true then
            label_entry.label:update(delta)
            already_updated[label_i_entry.label_i] = true
        end

        n_lines_updated = n_lines_updated + 1
        line_i = line_i + 1
    end

    -- backdrop animation
    if self._backdrop_should_resize then
        local should_reformat = false
        if self._backdrop_current_height ~= self._backdrop_target_height then
            local offset = rt.settings.textbox.backdrop_expand_speed * delta
            local current, target = self._backdrop_current_height, self._backdrop_target_height
            if current < target then
                self._backdrop_current_height = clamp(current + offset, 0, target)
                should_reformat = true
            elseif current > target then
                self._backdrop_current_height = clamp(current - offset, target)
                should_reformat = true
            end

        end

        if should_reformat then
            local x, y, width = rt.aabb_unpack(self._bounds)
            self._backdrop:fit_into(x, y, width, self._backdrop_current_height)

            local scrollbar_margin = 0
            local scrollbar_width = 10
            local scrollbar_height = self._backdrop_current_height
            local height = self:_calculate_n_visible_lines() * self._line_height

            self:_reformat_indicators()
        end
    end
end

--- @brief
function rt.TextBox:append(text)
    local entry = {
        raw = text,
        label = rt.Label(text),
        height = -1,             -- total heigh
        n_lines = -1,            -- number of rows
        line_height = -1,        -- height of one line
        seen = false,            -- has been rendered at least once
    }

    entry.text = text
    entry.label:realize()
    entry.label:fit_into(0, 0, self._labels_aabb.width, POSITIVE_INFINITY)
    entry.height = select(2, entry.label:measure())
    entry.line_height = entry.label:get_line_height()
    entry.n_lines = entry.label:get_n_lines()

    table.insert(self._labels, entry)
    self._n_labels = self._n_labels + 1

    local label_i = self._n_labels
    local line_i = self._n_lines
    for i = 1, entry.n_lines do
        self._line_i_to_label_i[line_i + 1] = {
            label_i = label_i,
            offset = i - 1
        }
        line_i = line_i + 1
    end

    self._n_lines = self._n_lines + entry.n_lines

    table.insert(self._scrolling_labels, {
        label = entry.label,
        entry = entry,
        elapsed = 0
    })
    self._n_scrolling_labels = self._n_scrolling_labels + 1
    entry.label:set_n_visible_characters(0)

    if self._n_lines < self._max_n_visible_lines then
        entry.seen = true
    end

    self:_update_indicators()
end

--- @brief
function rt.TextBox:draw()
    if self._n_labels == 0 then return end
    rt.graphics.push()

    if self._alignment == rt.TextBoxAlignment.BOTTOM then
        rt.graphics.translate(0,
            self._bounds.height - self._backdrop_current_height
        )
    end

    self._backdrop:draw()

    self._scrollbar:draw()
    self._scroll_up_indicator:draw()
    self._scroll_down_indicator:draw()

    --[[
    TODO: when is scrollbar visible
    hide / show scrollbar animation
    hide / show direction indicator
    continue indicator
    waiting for advance, advance, auto advance
    auto scroll beats
    ]]--

    rt.graphics.stencil(128, self._labels_stencil_mask)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, 128)

    rt.graphics.translate(self._labels_aabb.x, self._labels_aabb.y)

    local n_lines_drawn = 0
    local line_i = clamp(self._first_visible_line, 1)
    local already_drawn = {}

    while n_lines_drawn < self._max_n_visible_lines and line_i <= self._n_lines do
        local label_i_entry = self._line_i_to_label_i[line_i]
        if label_i_entry == nil then break end
        local label_entry = self._labels[label_i_entry.label_i]

        if already_drawn[label_i_entry.label_i] ~= true then
            rt.graphics.translate(0, -1 * label_i_entry.offset * label_entry.line_height)
            label_entry.label:draw()
            label_entry.seen = true
            rt.graphics.translate(0,  1 * label_i_entry.offset * label_entry.line_height)
            already_drawn[label_i_entry.label_i] = true
        end

        rt.graphics.translate(0, label_entry.line_height)
        line_i = line_i + 1
        n_lines_drawn = n_lines_drawn + 1
    end

    rt.graphics.set_stencil_test()
    rt.graphics.pop()
end

--- @brief get whether all text was scrolled completely
function rt.TextBox:get_is_finished()
    return self._n_scrolling_labels == 0
end

function rt.TextBox:_can_scroll_up()
    return self._first_visible_line > 1
end

function rt.TextBox:_can_scroll_down()
    return not (self._first_visible_line + self:_calculate_n_visible_lines() > self._n_lines)
end

--- @brief
function rt.TextBox:scroll_up()
    if self:_can_scroll_up() then
        self._first_visible_line = self._first_visible_line - 1
        self:_update_indicators()
    end
end

--- @brief
function rt.TextBox:scroll_down()
    if self:_can_scroll_down() then
        self._first_visible_line = self._first_visible_line + 1
        self:_update_indicators()
    end
end