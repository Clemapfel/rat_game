rt.settings.overworld.trigger = {
    debug_color = rt.Palette.RED_1,
    is_trigger_key = "is_trigger"
}

--- @class ow.Trigger
--- @brief object that invokes a callback when the player interacts with it
ow.Trigger = meta.new_type("Trigger", ow.OverworldEntity, rt.SignalEmitter, function(scene, x, y, width, height)
    local out = meta.new(ow.Trigger, {
        _scene = scene,
        _active = true,
        _is_solid = false,
        _collider_bounds = rt.AABB(x, y, width, height),
        _collider = {}, -- rt.RectangleCollider
        _debug_shape = {}, -- rt.Rectangle
        _debug_shape_outline = {}, -- rt.Rectangle
        _debug_state_overlay = {}, -- rt.Rectangle
        _intersect_active = false,
        _interact_active = false
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
    local offset = 0.4
    self._debug_state_overlay:set_color(rt.RGBA(color.r + offset, color.g + offset, color.b + offset, 0.9))
    self:_update_collider()

    self._collider:signal_connect("contact_begin", function(_, other, contact, self)
        if not self._active then return end
        local keys = rt.settings.overworld.player
        if other:get_userdata(keys.is_player_key) then
            self._intersect_active = true
        end

        if other:get_userdata(keys.is_player_sensor_key) then
            self._interact_active = true
        end
    end, self)

    self._collider:signal_connect("contact_end", function(_, other, contact, self)
        if not self._active then return end
        local keys = rt.settings.overworld.player
        if other:get_userdata(keys.is_player_key) then
            self._intersect_active = false
        end

        if other:get_userdata(keys.is_player_sensor_key) then
            self._interact_active = false
        end
    end, self)

    self._is_realized = true
end

function ow.Trigger:set_is_solid(b)
    if b ~= self._is_solid then
        self._is_solid = b
        self:_update_collider()
    end
end

--- @brief [internal]
function ow.Trigger:_update_collider()
    self._collider:set_is_active(self._active)
    self._collider:set_is_sensor(not self._is_solid)

    local keys = rt.settings.overworld.trigger
    self._collider:add_userdata(keys.is_trigger_key, true)
    self._collider:add_userdata("instance", self)

    self._collider:signal_connect("contact_begin", ow.Trigger._on_collider_contact, self)
end

--- @brief [internal]
function ow.Trigger._on_collider_contact(_, other, contact, self)
    if not self._active then return end
    local keys = rt.settings.overworld.player

    if other:get_userdata(keys.is_player_key) then
        self:signal_emit("intersect", other:get_userdata("instance"))
    end

    if other:get_userdata(keys.is_player_sensor_key)  then
        self:signal_emit("interact", other:get_userdata("instance"))
    end
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

            if self._intersect_active or self._intersect_active then
                self._debug_state_overlay:draw()
            end

            self._debug_shape_outline:draw()
        end
    end
end