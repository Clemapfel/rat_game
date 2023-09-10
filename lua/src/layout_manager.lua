--- @class LayoutManager
rt.LayoutManager = meta.new_type("LayoutManager", function()
    local out = meta.new(rt.LayoutManager, {})
    return out
end)

function rt.LayoutManager.reformat(self)
    assert("[rt] In rt.LayoutManager:reformat: Called abstract method")
end


--- @class Bin
--- @brief Layout with a single child
rt.Bin = meta.new_type("Bin", function()
    local out = meta.new(rt.Bin, {
        child = {}
    }, rt.Layoutmanager)
    rt.add_signal_component(out)

    getmetatable(out).components.signal:connect("notify::child", function(self)
        rt.LayoutManager.reformat(self)
        println("called")
    end)

    return out
end)

--- @brief
function rt.Bin.set_child(self, child)
    meta.assert_isa(self, rt.Bin)
    meta.assert_object(child)
    self.child = child
end

--- @brief
function rt.Bin.remove_child(self)
    meta.assert_isa(self, rt.Bin)
    self.child = nil
end