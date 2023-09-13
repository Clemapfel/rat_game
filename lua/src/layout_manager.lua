--- @class rt.LayoutMode
rt.LayoutMode = meta.new_enum({
    NONE = "LAYOUT_MODE_NONE",
    BIN = "LAYOUT_MODE_BIN",
    LIST = "LAYOUT_MODE_LIST",
    GRID = "LAYOUT_MODE_GRID",
    OVERLAY = "LAYOUT_MODE_OVERLAY"
})

--- @class rt.LayoutComponent
rt.LayoutComponent = meta.new_type("LayoutComponent", function()
    local out = meta.new(rt.LayoutComponent, {
        _parent = nil,
        _children = {},
        _mode = 1
    }, rt.AllocationComponent)
    return out
end)

function rt.LayoutComponent.reformat(self, bounds)
    meta.assert_isa(self, rt.LayoutComponent)
    meta.assert_isa(bounds, rt.Rectangle)


end

