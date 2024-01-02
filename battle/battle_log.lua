rt.settings.battle_log = {
    scrollbar_width = 3 * rt.settings.margin_unit,
}

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
        _n_lines = 0,
        _offset = 0,
        _line_width = 1,

        _labels = {}, -- Table<rt.Label>

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

    local temp = rt.Spacer()
    temp:set_color(rt.Palette.YELLOW)
    out._viewport:set_child(temp)

    out._scrollbar:signal_connect("value_changed", function(_, value, self)
        local line_i = value * self._n_lines
        -- TODO
    end, out)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", function(_, which, self)
        if which == rt.InputButton.UP then
            self._scrollbar:scroll_up(1 / self._n_lines)
        elseif which == rt.InputButton.DOWN then
            self._scrollbar:scroll_down(1 / self._n_lines)
        end
    end, out)

    return out
end)

--- @overload
function bt.BattleLog:get_top_level_widget()
    return self._frame
end

--- @overload
function bt.BattleLog:draw()
    self._frame:draw()
    for _, label in pairs(self._labels) do
        label:draw()
    end
end

--- @overload
function bt.BattleLog:push_back(line)
    local label = rt.Label(line)
    local x, y = 0, 0--self._viewport:get_position()
    local w, h = self._viewport:get_size()
    label:realize()
    label:fit_into(x, y, w, h)
    label:set_is_animated(true)
    table.insert(self._labels, label)
    println(line)
end