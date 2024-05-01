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

        _alignment = rt.TextBoxAlignment.TOP,

        _continue_indicator_visible = true,
        _continue_indicator = rt.DirectionIndicator(rt.Direction.DOWN),

        _scrollbar_visible = true,
        _scrollbar = rt.Scrollbar(),
        _scroll_up_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _scroll_down_indicator = rt.DirectionIndicator(rt.Direction.DOWN),

        _backdrop_should_resize = true,
        _backdrop_current_height = 0,
        _backdrop_target_height = 100,

        _scrolling_labels = {}
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

function rt.TextBox:_backdrop_height_from_n_lines(n_lines)
    local frame_size = self._backdrop:get_thickness()
    local m = rt.settings.margin_unit
    return n_lines * self._line_height + 2 * frame_size + 2 * m
end

--- @brief
function rt.TextBox:size_allocate(x, y, width, height)
    local frame_size = self._backdrop:get_thickness()
    local m = rt.settings.margin_unit
    self._labels_aabb = rt.AABB(
        x + frame_size + m,
        y + frame_size + m,
        width - 2 * frame_size - 2 * m,
        height - 2 * frame_size - 2 * m
    )

    self._labels_stencil_mask:resize(
        x + frame_size + m,
        y + frame_size + m,
        width - 2 * frame_size - 2 * m,
        self._max_n_visible_lines * self._line_height
    )

    if self._backdrop_should_resize == false then
        self._backdrop:fit_into(x, y, width, self:_backdrop_height_from_n_lines(self._max_n_visible_lines))
    else
        self._backdrop:fit_into(x, y, width, self._backdrop_current_height)
    end

    self._backdrop_target_height = self._max_n_visible_lines * self._line_height + 2 * frame_size + 2 * m

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
            entry.line_i_to_y = {}
            for i = 1, entry.n_lines do
                entry.line_i_to_y[i] = current_offset
                current_offset = current_offset + entry.line_height
            end

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
end

--- @brief
function rt.TextBox:update(delta)
    if not self._is_realized then return end

    -- text scrolling
    local step = 1 / rt.settings.textbox.scroll_speed
    local to_remove = {}
    for label, elapsed in pairs(self._scrolling_labels) do
        local new_elapsed = elapsed + delta
        local n_letters = math.floor(new_elapsed / step)
        label:set_n_visible_characters(n_letters)
        if n_letters > label:get_n_characters() then
            table.insert(to_remove, label)
        else
            self._scrolling_labels[label] = new_elapsed
        end
        self._scrolling_labels[label] = new_elapsed
    end

    for label in values(to_remove) do
        self._scrolling_labels[label] = nil
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
        end
    end
end

--- @brief
function rt.TextBox:append(text)
    local entry = {
        raw = text,
        label = rt.Label(text),
        height = -1,
        n_lines = -1,
        line_height = -1,
        line_i_to_y = {}
    }

    entry.text = text
    entry.label:realize()
    entry.label:fit_into(0, 0, self._labels_aabb.width, POSITIVE_INFINITY)
    entry.height = select(2, entry.label:measure())
    entry.line_height = entry.label:get_line_height()
    entry.n_lines = entry.label:get_n_lines()
    entry.line_i_to_y = {}
    for i = 1, entry.n_lines do
        entry.line_i_to_y[i] = self._total_height
        self._total_height = self._total_height + entry.line_height
    end

    table.insert(self._labels, entry)
    self._n_labels = self._n_labels + 1

    local label_i = self._n_labels
    local line_i = self._n_lines
    for i = 1, entry.n_lines do
        self._line_i_to_label_i[self._n_lines + 1] = {
            label_i = label_i,
            offset = i - 1
        }
        self._n_lines = self._n_lines + 1
    end

    self._scrolling_labels[entry.label] = 0
    entry.label:set_n_visible_characters(0)
end

--- @brief
function rt.TextBox:draw()
    if self._n_labels == 0 then return end
    rt.graphics.push()

    self._backdrop:draw()

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
            rt.graphics.translate(0,  1 * label_i_entry.offset * label_entry.line_height)
            already_drawn[label_i_entry.label_i] = true
        end

        rt.graphics.translate(0, label_entry.line_height)
        line_i = line_i + 1
    end


    rt.graphics.set_stencil_test()
    rt.graphics.pop()
end
