rt.settings.battle_log = {
    scrollbar_width = 3 * rt.settings.margin_unit,
    indicator_idle_color = rt.Palette.GRAY_4,
    indicator_active_color = rt.Palette.GRAY_1,
    scroll_speed = 10, -- letters per second
}

--- @class bt.BattleLogTextLayout
bt.BattleLogTextLayout = meta.new_type("BattleLogTextLayout", rt.Widget, function()
    local out = meta.new(bt.BattleLogTextLayout, {
        _children = {},                    -- Table<rt.Widget>
        _children_heights = {},            -- Table<Number>
        _cumulative_children_heights = {}, -- Table<Number>
        _area = rt.AABB(0, 0, 1, 1),
        _index = 1,
        _n_children = 0
    })
    out._cumulative_children_heights[0] = 0 -- sic
    return out
end)

--- @overload
function bt.BattleLogTextLayout:draw()
    if not self:get_is_visible() or self._n_children == 0 then
        return
    end
    local i = self._index
    local h = 0

    local offset = ternary(i > 1, -1 * self._cumulative_children_heights[i-1], 0)
    rt.graphics.translate(0, offset)

    while i <= self._n_children and h <= self._area.height do
        self._children[i]:draw()
        h = h + self._children_heights[i]
        i = i + 1
    end
end

--- @overload
function bt.BattleLogTextLayout:realize()
    for _, child in pairs(self._children) do
        child:realize()
    end
    rt.Widget.realize(self)
end

--- @overload
function bt.BattleLogTextLayout:size_allocate(x, y, width, height)
    local area = rt.AABB(x, y, width, height)
    self._children_heights = {}
    self._cumulative_children_heights = {}
    self._cumulative_children_heights[0] = 0 -- sic

    for i = 1, self._n_children do
        local child = self._children[i]
        child:fit_into(area.x, area.y, width, height)

        local h = select(2, child:measure())
        area.y = area.y + h
        self._children_heights[i] = h
        self._cumulative_children_heights[i] = self._cumulative_children_heights[i-1] + h
    end

    self._area = area
end

--- @brief
function bt.BattleLogTextLayout:push_back(child)
    table.insert(self._children, child)
    child:set_parent(self)
    if self:get_is_realized() then child:realize() end

    local area = self._area
    child:fit_into(area.x, area.y, area.width, POSITIVE_INFINITY)

    local h = select(2, child:measure())
    area.y = area.y + h
    self._children_heights[self._n_children+1] = h
    self._cumulative_children_heights[self._n_children+1] = self._cumulative_children_heights[self._n_children] + h
    self._n_children = self._n_children + 1
end

--- @brief
function bt.BattleLogTextLayout:scroll_up()
    if self._index > 1 then
        self._index = self._index - 1
    end
end

--- @brief
function bt.BattleLogTextLayout:scroll_down()
    if self._index < self._n_children then
        self._index = self._index + 1
    end
end

--- @class bt.BattleLog
bt.BattleLog = meta.new_type("BattleLog", rt.Widget, rt.Animation, function()
    local out = meta.new(bt.BattleLog, {
        _frame = rt.Frame(rt.FrameType.RECTANGULAR),
        _backdrop = rt.Spacer(),
        _backdrop_overlay = rt.OverlayLayout(),
        _up_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _down_indicator = rt.DirectionIndicator(rt.Direction.DOWN),
        _scrollbar = rt.Scrollbar(rt.Orientation.VERTICAL),
        _scrollbar_layout = rt.ListLayout(rt.Orientation.VERTICAL),
        _scrollbar_layout_revealer = rt.RevealLayout(),
        _viewport = rt.Viewport(),
        _viewport_scrollbar_layout = rt.ListLayout(rt.Orientation.HORIZONTAL),

        _lines = {}, -- Table<String>
        _labels_layout = bt.BattleLogTextLayout(),

        _input = {}, -- rt.InputController
        _scrollbar_offset = 0,

        _active_label = {}, -- rt.Label
        _elapsed = 0
    })

    out._scrollbar_layout:push_back(out._up_indicator)
    out._scrollbar_layout:push_back(out._scrollbar)
    out._scrollbar_layout:push_back(out._down_indicator)

    out._up_indicator:set_expand_vertically(false)
    out._down_indicator:set_expand_vertically(false)
    out._up_indicator:set_vertical_alignment(rt.Alignment.START)
    out._down_indicator:set_vertical_alignment(rt.Alignment.END)

    local m = rt.settings.battle_log.scrollbar_width
    local outer_margin = rt.settings.margin_unit + out._frame:get_thickness()

    out._scrollbar:set_minimum_size(m, 0)
    out._scrollbar_layout:set_spacing(rt.settings.margin_unit)
    out._scrollbar_layout:set_horizontal_alignment(rt.Alignment.END)
    out._scrollbar_layout:set_margin_horizontal(outer_margin)

    out._scrollbar_layout_revealer:set_child(out._scrollbar_layout)

    out._scrollbar_layout_revealer:set_margin_vertical(outer_margin)
    out._scrollbar_layout_revealer:set_margin_horizontal(outer_margin)

    for indicator in range(out._up_indicator, out._down_indicator) do
        indicator:set_minimum_size(m, m)
    end

    out._viewport_scrollbar_layout:set_spacing(0.5 * m) -- TODO: why is this necessary?

    local spacer = rt.Spacer()
    spacer:set_color(rt.Palette.YELLOW)
    out._viewport_scrollbar_layout:push_back(out._viewport)
    out._viewport_scrollbar_layout:push_back(out._scrollbar_layout_revealer)

    out._viewport:set_expand_horizontally(true)

    out._viewport:set_margin_left(outer_margin)

    out._backdrop_overlay:set_base_child(out._backdrop)
    out._backdrop_overlay:push_overlay(out._viewport_scrollbar_layout)
    out._frame:set_child(out._backdrop_overlay)

    out._viewport:set_child(out._labels_layout)
    out._labels_layout:set_margin_left(outer_margin)
    out._labels_layout:set_margin_vertical(2 * outer_margin)

    for indicator in range(out._up_indicator, out._down_indicator, out._scrollbar._cursor) do
        indicator:set_color(rt.settings.battle_log.indicator_idle_color)
    end

    out._scrollbar:set_value(0)
    out._scrollbar_layout_revealer:set_is_revealed(false)
    out._scrollbar_layout_revealer:set_expand_horizontally(false)
    out._scrollbar_layout_revealer:set_margin_horizontal(2 * rt.settings.margin_unit)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", function(_, which, self)

        local before = self._labels_layout._index
        if which == rt.InputButton.UP then
            self._labels_layout:scroll_up()
            if self._labels_layout._index ~= before then
                self._up_indicator:set_color(rt.settings.battle_log.indicator_active_color)
                self._scrollbar:set_value((self._labels_layout._index - 1) / (#self._labels_layout._children - 1))
            end
        elseif which == rt.InputButton.DOWN then
            self._labels_layout:scroll_down()
            if self._labels_layout._index ~= before then
                self._down_indicator:set_color(rt.settings.battle_log.indicator_active_color)
                self._scrollbar:set_value((self._labels_layout._index - 1) / (#self._labels_layout._children - 1))
            end
        elseif which == rt.InputButton.B then
            self._scrollbar_layout_revealer:set_is_revealed(not self._scrollbar_layout_revealer:get_is_revealed())
        end
    end, out)

    out._input:signal_connect("released", function(_, which, self)
        if which == rt.InputButton.UP then
            self._scrollbar._cursor:set_color(rt.settings.battle_log.indicator_idle_color)
            self._up_indicator:set_color(rt.settings.battle_log.indicator_idle_color)
        elseif which == rt.InputButton.DOWN then
            self._scrollbar._cursor:set_color(rt.settings.battle_log.indicator_idle_color)
            self._down_indicator:set_color(rt.settings.battle_log.indicator_idle_color)
        end
    end, out)

    out._input:signal_connect("enter", function(_, x, y, self)
        self._scrollbar_layout_revealer:set_is_revealed(true)
    end, out)

    out._input:signal_connect("leave", function(_, x, y, self)
        self._scrollbar_layout_revealer:set_is_revealed(false)
    end, out)

    out:set_is_animated(true)
    return out
end)

--- @overload
function bt.BattleLog:get_top_level_widget()
    return self._frame
end

--- @overload
function bt.BattleLog:update(delta)
    self._elapsed = self._elapsed + delta
    local step = 1 / rt.settings.battle_log.scroll_speed

    local n_letters = 0
    while self._elapsed >= step do
        self._elapsed = self._elapsed - step
        n_letters = n_letters + 1
    end

    if meta.is_label(self._active_label) then
        self._active_label:set_n_visible_characters(self._active_label:get_n_visible_characters() + n_letters)
    end
end

--- @overload
function bt.BattleLog:push_back(line)

    if not self:get_is_animated() then
        self:set_is_animated(true)
    end

    local label = rt.Label(line)
    label:set_alignment(rt.Alignment.START)
    label:set_n_visible_characters(0)

    if meta.is_label(self._active_label) then
        self._active_label:set_n_visible_characters(POSITIVE_INFINITY)
    end
    self._active_label = label

    self._labels_layout:push_back(label)
    self._scrollbar:set_n_steps(self._scrollbar:get_n_steps() + 1)

    self._labels_layout:scroll_down()
end

-- TODO
function bt.BattleLog:draw()
    self._frame:draw()
    self._scrollbar_layout_revealer:draw_bounds()
end