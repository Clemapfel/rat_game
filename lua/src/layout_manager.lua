--- @class rt.LayoutManager
rt.LayoutManager = meta.new_type("LayoutManager", function()
    local out = meta.new(rt.LayoutManager)
    meta._install_property(out, "allocation", rt.AllocationComponent(out))
    return out
end)

function rt.LayoutManager._bin_layout(self, children)
    local bounds = rt.get_allocation_component(self):get_bounds()

end