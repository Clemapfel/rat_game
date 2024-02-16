--- @class ow.InteractTrigger
--- @brief interactable solid, triggered by ow.Player._on_contact
--- @signal activate (self, player) -> nil
ow.InteractTrigger = meta.new_type("InteractTrigger", rt.SignalEmitter, rt.Drawable, function(world, x, y, width, height, on_activate)
    local out = meta.new(ow.InteractTrigger, {
        _world = world,
        _collider = {}, -- rt.RectangleCollider
        _shape = {}     -- rt.Rectangle
    })

    x = which(x, 0)
    y = which(y, 0)
    width = which(width, 1)
    height = which(height, 1)

    out._shape = rt.Rectangle(x, y, width, height)
    out._shape:set_is_outline(false)

    out._collider = rt.RectangleCollider(world, rt.ColliderType.KINEMATIC, x, y, width, height)
    out._collider:add_userdata("instance", out)
    out:signal_add("activate")

    if not meta.is_nil(on_activate) then
        out:signal_connect("activate", on_activate)
    end
    return out
end)

--- @brief
function ow.InteractTrigger:get_bounds()
    return self._collider:get_bounds()
end

--- @overload
function ow.InteractTrigger:draw()
    self._shape:draw()
end