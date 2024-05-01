rt.settings.textbox = {
    scroll_speed = 40, -- letters per second
    backdrop_opacity = 0.8
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
        _current_backdrop_height = 0,
        _target_backdrop_height = 0,

        _labels_aabb = rt.AABB(0, 0, 1, 1),
        _labels_stencil_mask = rt.Rectangle(0, 0, 1, 1),
        _labels = {}, -- Table<rt.Label, cf. append>
        _scrolling_labels = {}, -- Set<Unsigned>
        _labels_height_sum = 0,
        _n_labels = 0,

        _first_visible_line = 1,
        _min_n_visible_lines = 4,
        _max_n_visible_lines = 4,

        _alignment = rt.TextBoxAlignment.TOP,

        _continue_indicator_visible = true,
        _continue_indicator = rt.DirectionIndicator(rt.Direction.DOWN),

        _scrollbar_visible = true,
        _scrollbar = rt.Scrollbar(),
        _scroll_up_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _scroll_down_indicator = rt.DirectionIndicator(rt.Direction.DOWN),
    })
end)

--[[
push(string) -> ID
push_require_advance()
is_finished(ID)     -- is scrolling finished
finish(ID)          -- finish scrolling, go into hold. if already holding, no effect
skip(ID)            -- jump to end of hold, no matter what

advance         -- if waitin for advance, advance, otherwise finish scrolling all
set_advance_automatically(b)

set_scroll_mode(bool)       expand, if at the bottom of the screen, up, if at the top, down
scroll_up       -- only works in scroll mode
scroll_down
]]--

--- @override
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
end

---
function rt.TextBox:size_allocate(x, y, width, height)

    local frame_size = self._backdrop:get_thickness()
    local m = rt.settings.margin_unit
    self._labels_aabb = rt.AABB(
        x + frame_size + m,
        y + frame_size + m,
        width - 2 * frame_size - 2 * m,
        height - 2 * frame_size - 2 * m
    )

    if width ~= self._labels_aabb.width then
        -- reformat everything
        self._labels_height_sum = 0
        for entry in values(self._labels) do
            entry.label:fit_into(0, 0, self._labels_aabb.width, POSITIVE_INFINITY)
            entry.height = select(2, entry.label:measure())
            entry.n_lines = entry.label:get_n_lines()
            self._labels_height_sum = self._labels_height_sum + entry.height
        end
    end
end

---
function rt.TextBox:append(text)
    local w = self._labels_aabb.width
    local to_push = {
        raw = text,
        label = rt.Label(text),
        height = -1, -- height of this line
        n_lines = -1, -- number of lines
        elapsed = 0, -- seconds
        scrolling_done = false,
    }

    to_push.label:realize()
    to_push.label:fit_into(0, 0, self._labels_aabb.width, POSITIVE_INFINITY)
    to_push.height = select(2, to_push.label:measure())
    to_push.label:set_n_visible_characters(0)
    to_push.n_lines = to_push.label:get_n_lines()
    self._labels_height_sum = self._labels_height_sum + to_push.height
    table.insert(self._labels, to_push)
    self._n_labels = self._n_labels + 1
    self._scrolling_labels[self._n_labels] = true
end

--- @brief
function rt.TextBox:update(delta)
    -- text scrolling
    local step = 1 / rt.settings.textbox.scroll_speed
    for index in keys(self._scrolling_labels) do
        local entry = self._labels[index]
        entry.elapsed = entry.elapsed + delta
        local n_letters = math.floor(entry.elapsed / step)
        entry.label:set_n_visible_characters(n_letters)
        if n_letters > entry.label:get_n_characters() then
            entry.scrolling_done = true
        end

        if entry.scrolling_done == true then
        end
    end

    -- text animation
    local n_lines_drawn = 0
    local label_i = self._first_visible_line
    local line_height = 0
    local total_height = 0
    while n_lines_drawn < self._max_n_visible_lines do
        if label_i > self._n_labels then break end
        local entry = self._labels[label_i]
        entry.label:update(delta)
        n_lines_drawn = n_lines_drawn + entry.n_lines
        label_i = label_i + 1
        line_height = math.max(line_height, entry.label:get_line_height())
        total_height = total_height + entry.height
    end

    local frame_size = self._backdrop:get_thickness()
    local m = rt.settings.margin_unit
    self._target_backdrop_height = math.max(total_height + 2 * m + 2 * frame_size, self._min_n_visible_lines * line_height)

    self._labels_stencil_mask:resize(self._labels_aabb.x, self._labels_aabb.y, self._labels_aabb.width,  math.min(total_height, self._max_n_visible_lines * line_height))

    -- backdrop resize animation
    if self._current_backdrop_height ~= self._target_backdrop_height then
        local offset = rt.settings.textbox.backdrop_expand_speed * delta

        local should_reformat = false
        if self._current_backdrop_height < self._target_backdrop_height then
            self._current_backdrop_height = self._current_backdrop_height + offset
            if self._current_backdrop_height > self._target_backdrop_height then
                self._current_backdrop_height = self._target_backdrop_height
            end
            should_reformat = true
        elseif self._current_backdrop_height > self._target_backdrop_height then
            self._current_backdrop_height = self._current_backdrop_height - 2 * offset
            if self._current_backdrop_height < self._target_backdrop_height then
                self._current_backdrop_height = self._target_backdrop_height
            end
            should_reformat = true
        end

        if should_reformat then
            local bounds = self._bounds
            self._backdrop:fit_into(bounds.x, bounds.y, bounds.width, self._current_backdrop_height)

            bounds = rt.AABB(rt.aabb_unpack(self._labels_aabb))
            bounds.height = self._current_backdrop_height
            local indicator_radius = 20

            self._scroll_up_indicator:fit_into(
                bounds.x + bounds.width - indicator_radius,
                bounds.y,
                indicator_radius, indicator_radius
            )

            local top_margin = select(2, self._scroll_up_indicator:get_position()) - self._bounds.y
            self._scroll_down_indicator:fit_into(
                bounds.x + bounds.width - indicator_radius,
                bounds.y + bounds.height - indicator_radius - self._backdrop:get_thickness() - 2 * m,
                indicator_radius, indicator_radius
            )

            local scrollbar_width = 0.75 * indicator_radius
            local scrollbar_margin = indicator_radius - scrollbar_width
            self._scrollbar:fit_into(
                bounds.x + bounds.width - 0.5 * indicator_radius - 0.5 * scrollbar_width,
                bounds.y + indicator_radius + scrollbar_margin,
                scrollbar_width,
                bounds.height - 2 * indicator_radius - 2 * scrollbar_margin - self._backdrop:get_thickness() - 2  * m
            )
        end
    end

    self._scrollbar:set_page_index(self._first_visible_line)
    self._scrollbar:set_n_pages(self._n_labels)
end

--- @brief
function rt.TextBox:draw()
    rt.graphics.push()
    if self._alignment == rt.TextBoxAlignment.BOTTOM then
        rt.graphics.translate(0,
            self._bounds.height - self._current_backdrop_height
        )
    end

    self._backdrop:draw()

    for widget in range(
        --self._continue_indicator,
        self._scroll_up_indicator,
        self._scroll_down_indicator,
        self._scrollbar
    ) do
        widget:draw()
    end

    rt.graphics.stencil(128, self._labels_stencil_mask)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, 128)

    rt.graphics.translate(self._labels_aabb.x, self._labels_aabb.y)
    local n_lines_drawn = 0
    local label_i = self._first_visible_line
    while n_lines_drawn < self._max_n_visible_lines do
        if label_i > self._n_labels then break end
        local entry = self._labels[label_i]
        entry.label:draw()
        rt.graphics.translate(0, entry.height)
        n_lines_drawn = n_lines_drawn + entry.n_lines
        label_i = label_i + 1
    end

    rt.graphics.set_stencil_test()
    rt.graphics.pop()
end

--- @brief
function rt.TextBox:set_first_visible_line(index)
    if index < 1 then index = 1 end

    self._scroll_up_indicator:set_opacity(ternary(index < 1, 0.1, 1))
    self._scroll_down_indicator:set_opacity(ternary(index >= self._n_labels, 0.1, 1))
    self._first_visible_line = index
end

--- @brief
function rt.TextBox:get_first_visible_line()
    return self._first_visible_line
end

--- @brief
function rt.TextBox:set_alignment(alignment)
    meta.assert_enum(alignment, rt.TextBoxAlignment)
    self._alignment = alignment
end