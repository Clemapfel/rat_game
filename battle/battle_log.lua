rt.settings.battle_log = {
    scrollbar_width = 3 * rt.settings.margin_unit,
}

--- @class BattleLogTextLayout
bt.BattleLogTextLayout = meta.new_type("BattleLogTextLayout", function()
    local out = meta.new(bt.BattleLogTextLayout, {
        _children = {},                    -- Table<rt.Widget>
        _children_heights = {},            -- Table<Number>
        _cumulative_children_heights = {}, -- Table<Number>
        _area = rt.AABB(0, 0, 1, 1),
        _index = 1,
        _n_children = 0
    }, rt.Widget, rt.Drawable)
    out._cumulative_children_heights[0] = 0
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
    love.graphics.translate(0, offset)

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

--- @class BattleLog
bt.BattleLog = meta.new_type("BattleLog", function()
    local out = meta.new(bt.BattleLog, {
        _frame = rt.Frame(rt.FrameType.RECTANGULAR),
        _backdrop = rt.Spacer(),
        _backdrop_overlay = rt.OverlayLayout(),
        _up_indicator = rt.DirectionIndicator(rt.Direction.UP),
        _down_indicator = rt.DirectionIndicator(rt.Direction.DOWN),
        _scrollbar = rt.Scrollbar(rt.Orientation.VERTICAL),
        _scrollbar_layout = rt.ListLayout(rt.Orientation.VERTICAL),
        _viewport = rt.Viewport(),
        _viewport_scrollbar_layout = rt.ListLayout(rt.Orientation.HORIZONTAL),

        _lines = {}, -- Table<String>
        _labels_layout = bt.BattleLogTextLayout(),

        _input = {} -- rt.InputController
    }, rt.Widget, rt.Drawable)

    out._scrollbar_layout:push_back(out._up_indicator)
    out._scrollbar_layout:push_back(out._scrollbar)
    out._scrollbar_layout:push_back(out._down_indicator)

    out._up_indicator:set_expand_vertically(false)
    out._down_indicator:set_expand_vertically(false)
    out._up_indicator:set_vertical_alignment(rt.Alignment.START)
    out._down_indicator:set_vertical_alignment(rt.Alignment.END)

    local m = rt.settings.battle_log.scrollbar_width
    out._scrollbar:set_minimum_size(m, 0)
    out._scrollbar_layout:set_spacing(rt.settings.margin_unit)

    local outer_margin = rt.settings.margin_unit + out._frame:get_thickness()
    out._scrollbar_layout:set_margin_vertical(outer_margin)
    out._scrollbar_layout:set_margin_horizontal(outer_margin)
    out._scrollbar_layout:set_horizontal_alignment(rt.Alignment.END)

    for _, indicator in pairs({out._up_indicator, out._down_indicator}) do
        indicator:set_minimum_size(m, m)
    end

    out._viewport_scrollbar_layout:push_back(out._viewport)
    out._viewport_scrollbar_layout:push_back(out._scrollbar_layout)

    out._viewport:set_expand_horizontally(true)
    out._scrollbar_layout:set_expand_horizontally(false)

    out._viewport:set_margin_left(outer_margin)
    out._viewport:set_margin_top(outer_margin)
    out._viewport:set_margin_bottom(outer_margin)

    out._backdrop_overlay:set_base_child(out._backdrop)
    out._backdrop_overlay:push_overlay(out._viewport_scrollbar_layout)
    out._frame:set_child(out._backdrop_overlay)
    out._viewport:set_child(out._labels_layout)

    out._scrollbar:signal_connect("value_changed", function(_, value, self)
        local line_i = value * self._n_lines
        -- TODO
    end, out)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", function(_, which, self)
        if which == rt.InputButton.UP then
            self._labels_layout:scroll_up()
        elseif which == rt.InputButton.DOWN then
            self._labels_layout:scroll_down()
        end
    end, out)

    return out
end)

--- @overload
function bt.BattleLog:get_top_level_widget()
    return self._labels_layout
end

--- @overload
function bt.BattleLog:push_back(line)
    local label = rt.Label(line)
    label:set_alignment(rt.Alignment.START)
    --label:set_is_animated(true)
    self._labels_layout:push_back(label)
end