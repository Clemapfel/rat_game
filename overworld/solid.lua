--- @class ow.Interactable
ow.Interactable = meta.new_type("Interactable", function(world, x, y, width, height)
    local out = meta.new(ow.Interactable, {
        _world = world,
        _collider = {}, -- rt.RectangleCollider

        _is_interactable = false,
        _interact_callback = function()  end,

        _is_intersectable = false,
        _intersect_callback = function()  end
    }, rt.SignalEmitter, rt.Drawable)

    out._collider = rt.RectangleCollider(
        world, rt.ColliderType.KINEMATIC,
        which(x, 0), which(y, 0),
        which(width, 0), which(height, 0)
    )
    out._collider:set_userdata(out)

    out:signal_add("interact")
    out:signal_add("intersect")

    return out
end)

--- @brief
function ow.Interactable:get_bounds()
    return self._collider:get_bounds()
end

--- @overload
function ow.Interactable:draw()

    love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.width, bounds.height)
end