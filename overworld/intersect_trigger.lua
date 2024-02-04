--- @class ow.IntersectTrigger
--- @brief interactable solid, triggered by ow.Player._on_contact
--- @signal activate (self, player) -> nil
ow.IntersectTrigger = meta.new_type("IntersectTrigger", function(world, x, y, width, height, on_activate)
    local out = meta.new(ow.IntersectTrigger, {
        _world = world,
        _collider = {}, -- rt.RectangleCollider
        _shape = {},     -- rt.Rectangle
        _trigger_on_enter = true,
        _trigger_on_leave = true
    }, rt.SignalEmitter, rt.Drawable)

    x = which(x, 0)
    y = which(y, 0)
    width = which(width, 1)
    height = which(height, 1)

    out._shape = rt.Rectangle(x, y, width, height)
    out._shape:set_is_outline(true)
    
    out._collider = rt.RectangleCollider(world, rt.ColliderType.KINEMATIC, x, y, width, height)
    out._collider:set_is_sensor(true)
    out._collider:add_userdata("instance", out)
    out:signal_add("activate")

    if not meta.is_nil(on_activate) then
        out:signal_connect("activate", on_activate)
    end
    return out
end)

--- @brief
function ow.IntersectTrigger:get_bounds()
    return self._collider:get_bounds()
end

--- @overload
function ow.IntersectTrigger:draw()
    self._shape:draw()
end