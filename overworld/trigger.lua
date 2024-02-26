rt.settings.overworld.trigger = {
    debug_color = rt.Palette.RED_1
}

ow.TriggerType = meta.new_enum({
    ON_PLAYER_INTERACT,
    ON_PLAYER_INTERSECT,
    NEVER
})

--- @class ow.Trigger
--- @brief object that invokes a callback when the player interacts with it
ow.Trigger = meta.new_type("Trigger", ow.OverworldEntity, rt.SignalEmitter, function(scene, trigger_type, x, y, width, height)
    local out = meta.new(ow.Trigger, {
        _scene = scene,
        _active = true,
        _trigger_type = trigger_type,
        _collider_bounds = rt.AABB(x, y, width, height),
        _collider = {}, -- rt.RectangleCollider
        _debug_shape = {}, -- rt.Rectangle
        _debug_shape_outline = {}, -- rt.Rectangle
        _debug_state_overlay = {}, -- rt.Rectangle
        _currently_triggered = false,
        _on_interact = function() println("interacted") end,
        _on_intersect = function() println("intersected") end
    })
    out:signal_add("interact")
    out:signal_add("intersect")
    return out
end)

--- @override
function ow.Trigger:realize()
    local x, y, w, h = self._collider_bounds.x, self._collider_bounds.y, self._collider_bounds.width, self._collider_bounds.height
    self._collider = rt.RectangleCollider(self._scene._world, rt.ColliderType.STATIC, x, y, w, h)

    self._debug_shape = rt.Rectangle(x, y, w, h)
    self._debug_shape_outline = rt.Rectangle(x, y, w, h)
    self._debug_shape_outline:set_is_outline(true)

    self._debug_state_overlay = rt.Rectangle(x, y, w, h)

    local color = rt.settings.overworld.trigger.debug_color
    self._debug_shape:set_color(rt.RGBA(color.r, color.g, color.b, 0.5))
    self._debug_shape_outline:set_color(rt.RGBA(color.r, color.g, color.b, 0.9))
    self._debug_state_overlay:set_color(rt.RGBA(1.5, 1.5, 1.5, 0.8)) -- sic

    self._is_realized = true
end

--- @brief [internal]
function ow.Trigger:_update_collider()
    if self._trigger_type == ow.TriggerType.NEVER then
        self._collider:set_active(false)
    elseif self._trigger_type == ow.TriggerType.ON_PLAYER_INTERACT then
        self._collider:set_active(true)
        self._collider:set_sensor(false)
    elseif self._trigger_type == ow.TriggerTyoe.ON_PLAYER_INTERSECT then
        self._collider:set_active(true)
        self._collider:set_sensor(true)
    end
    
    self._collider:add_userdata("is_trigger", true)
    self._collider:add_userdata("trigger_type", self._trigger_type)
    self._collider:add_userdata("self", self)
end

--- @override
function ow.Trigger:update(delta)
    if self._is_realized then
        -- noop
    end
end

--- @override
function ow.Trigger:draw()
    if self._is_realized then
        if self._scene:get_debug_draw_enabled() then
            self._debug_shape:draw()
            self._debug_shape_outline:draw()

            if self._currently_triggered then
                rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
                self._debug_state_overlay:draw()
                rt.graphics.set_blend_mode()
            end
        end
    end
end