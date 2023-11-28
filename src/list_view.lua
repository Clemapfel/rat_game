--- @class rt.ListView
rt.ListView = meta.new_type("ListView", function()
    local out = meta.new(rt.ListView, {
        _layout = rt.ListLayout(rt.Orientation.VERTICAL),
        _scrollbar = rt.Scrollbar(rt.Orientation.VERTICAL),
        _viewport = rt.Viewport(),
        _main = rt.BoxLayout(rt.Orientation.HORIZONTAL)
    }, rt.Widget, rt.Drawable)

    return out
end)

function rt.ListView:get_top_level_widget()
    meta.assert_isa(self, rt.ListView)
    return self._layout
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
    return out
end)

function rt.ListViewItem:get_top_level_widget()
    meta.assert_isa(self, rt.ListViewItem)
    return self._frame
end

--- @brief
function rt.ListView:push_back(child)
    self._layout:push_back(rt.ListViewItem(child))
end

