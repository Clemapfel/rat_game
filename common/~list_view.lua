--[[

rt.settings.list_view = {
    scrollbar_width = 2 * rt.settings.margin_unit
}

--- @class rt.ListView
rt.ListView = meta.new_type("ListView", function()
    local out = meta.new(rt.ListView, {
        _layout = rt.ListLayout(rt.Orientation.VERTICAL),
        _scrollbar = rt.Scrollbar(rt.Orientation.VERTICAL),
        _viewport = rt.Viewport(),
        _hbox = rt.BoxLayout(rt.Orientation.HORIZONTAL)
    }, rt.Widget, rt.Drawable)

    out._viewport:set_child(out._layout)

    out._viewport:set_propagate_width(true)

    out._hbox:push_back(out._viewport)
    out._hbox:push_back(out._scrollbar)

    out._scrollbar:set_expand_horizontally(false)
    out._scrollbar:set_minimum_size(rt.settings.list_view.scrollbar_width, 0)

    return out
end)

function rt.ListView:get_top_level_widget()

    return self._hbox
end

--- @class rt.ListViewItem
rt.ListViewItem = meta.new_type("ListViewItem", function(child)
    local out = meta.new(rt.ListViewItem, {
        _child = child,
        _backdrop = rt.Spacer(),
        _frame = rt.Frame(),
        _overlay = rt.OverlayLayout()
    }, rt.Widget, rt.Drawable)

    out._overlay:set_base_child(out._backdrop)
    out._overlay:push_overlay(out._child)
    out._frame:set_child(out._overlay)

    out._backdrop:set_corner_radius(0)
    out._frame:set_corner_radius(0)
    return out
end)

function rt.ListViewItem:get_top_level_widget()

    return self._frame
end

--- @brief
function rt.ListView:push_back(child)
    self._layout:push_back(rt.ListViewItem(child))
end
]]--

