--- @class mn.ItemGetScreen
mn.ItemGetScreen = meta.new_type("ItemGetScreen", rt.Widget, rt.Updatable, function(item)
    local out = meta.new(mn.ItemGetScreen, {
        _item = item
    })

    if item ~= nil then out:set_item(item) end
end)

--- @override
function mn.ItemGetScreen:realize()

end

--- @override
function mn.ItemGetScreen:size_allocate(x, y, width, height)

end

--- @override
function mn.ItemGetScreen:draw()

end

--- @override
function mn.ItemGetScreen:update(delta)

end

