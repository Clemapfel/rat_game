--- @class ListLayout
rt.ListLayout = meta.new_type("ListLayout", function()
    return meta.new(rt.ListLayout, {
        _children = rt.Queue()
    }, rt.Drawable, rt.Widget)
end)

--- @overload rt.Drawable.draw
function rt.ListLayout.draw()

end

--- @overlay