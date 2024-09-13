--- @brief
bt.StatusBar = meta.new_type("StatusBar", rt.Widget, function()
    return meta.new(bt.StatusBar, {
        _items = {},          -- Table<bt.StatusBar.Item>
        _object_to_item = {}, -- Table<Union<bt.Status, bt.Consumable>, bt.StatusBar.Item>
    })
end)

bt.StatusBar.Item = function(object)
    return {
        sprite = rt.LabeledSprite(object:get_sprite_id()),
        is_adding = false,
        is_adding_elapsed = 0,
        is_activating = false,
        is_activating_elapsed = 0,
        is_removing = false,
        is_removing_elapsed = 0
    }
end

--- @override
function bt.StatusBar:update(delta)
    
end

--- @override
function bt.StatusBar:realize()
    
end 

--- @override
function bt.StatusBar:size_allocate(x, y, width, height)
    
end 

--- @override
function bt.StatusBar:draw()
    
end 

--- @brief
function bt.StatusBar:add(status_or_consumable)
end 

--- @brief
function bt.StatusBar:remove(status_or_consumable)
end

--- @brief
function bt.StatusBar:activate(status_or_consumable)
end

--- @brief
function bt.StatusBar:set_label(status_or_consumable, label)
    
end

--- @brief
function bt.StatusBar:skip()
    
end

--- @brief
function bt.StatusBar:set_opacity(alpha)
    
end
