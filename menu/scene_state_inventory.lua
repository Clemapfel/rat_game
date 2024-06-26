--- @class mn.SceneState.INVENTORY
mn.SceneState.INVENTORY = meta.new_type("INVENTORY", mn.SceneState, function(scene)
    return meta.new(mn.SceneState.INVENTORY, {
        _scene = scene,
    })
end)

--- @override
function mn.SceneState.INVENTORY:handle_button_pressed(button)
end

--- @override
function mn.SceneState.INVENTORY:handle_button_released(button)
end

--- @override
function mn.SceneState.INVENTORY:enter()

end

--- @override
function mn.SceneState.INVENTORY:exit()

end

--- @override
function mn.SceneState.INVENTORY:update(delta)

end

--- @override
function mn.SceneState.INVENTORY:draw()

end