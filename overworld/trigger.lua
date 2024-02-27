rt.settings.overworld.trigger = {
    debug_color = rt.Palette.RED_1,
    is_trigger_key = "is_trigger"
}

--- @class ow.Trigger
--- @brief object that invokes a callback when the player interacts with it
--- @signal interact (ow.Trigger, ow.Player) -> nil
--- @signal intersect (ow.Trigger, ow.Player) -> nil
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
        _interact_active = false,
        _should_emit_interact = false,
        _should_emit_interact_data = nil,
        _should_emit_intersect = false,
        _should_emit_intersect_data = nil
    })
    out:signal_add("interact")
    out:signal_add("intersect")
    return out
end)

--- @override
function ow.Trigger:realize()
    self._is_realized = true
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

    self._collider:signal_connect("contact_begin", ow.Trigger._on_collider_contact_begin, self)
    self._collider:signal_connect("contact_end", ow.Trigger._on_collider_contact_end, self)

    -- update with world instead of animation so signals are emitted the same physics tick as the trigger is touched
    local previous = love.timer.getTime()
    self._scene._world:signal_connect("update", function(_, self)
        local current = love.timer.getTime()
        self:update(current - previous)
        previous = current
    end, self)

    self:set_is_active(self._active)
end

--- @brief
function ow.Trigger:set_is_active(b)
    self._active = b
    self._collider:set_is_active(b)
end

--- @brief [internal]
function ow.Trigger._on_collider_contact_begin(_, other, contact, self)
    if not self._active then return end
    local keys = rt.settings.overworld.player
    local player = other:get_userdata("instance")

    -- delay signal emission to update, because the physics world is locked during contacts
    if other:get_userdata(keys.is_player_key) then
        self._intersect_active = true
        self._should_emit_intersect = true
        self._should_emit_intersect_data = player
    end

    if other:get_userdata(keys.is_player_sensor_key) then
        if player:_try_consume_sensor() then
            self._interact_active = true
            self._should_emit_interact = true
            self._should_emit_interact_data = player
        end
    end
end

--- @brief [internal]
function ow.Trigger._on_collider_contact_end(_, other, contact, self)
    if not self._active then return end
    local keys = rt.settings.overworld.player
    if other:get_userdata(keys.is_player_key) then
        self._intersect_active = false
    end

    if other:get_userdata(keys.is_player_sensor_key) then
        self._interact_active = false
    end
end

--- @brief
function ow.Trigger:set_is_solid(b)
    self._is_solid = b
    if self._is_realized then
        self._collider:set_is_sensor(not b)
    end
end

--- @brief [internal]
function ow.Trigger:_update_collider()
    if self._is_realized then
        self._collider:set_is_active(self._active)
        self._collider:set_is_sensor(not self._is_solid)
        println(self._collider:get_is_sensor())

        local keys = rt.settings.overworld.trigger
        self._collider:add_userdata(keys.is_trigger_key, true)
        self._collider:add_userdata("instance", self)
    end
end

--- @override
function ow.Trigger:update(delta)
    if self._is_realized then
        if self._should_emit_intersect then
            self:signal_emit("intersect", self._should_emit_intersect_data)
            self._should_emit_intersect = false
            self._should_emit_intersect_data = nil
        end

        if self._should_emit_interact then
            self:signal_emit("interact", self._should_emit_interact_data)
            self._should_emit_interact = false
            self._should_emit_interact_data = nil
        end
    end
end

--- @override
function ow.Trigger:draw()
    if self._is_realized then
        if self._scene:get_debug_draw_enabled() then
            if self._active then
                self._debug_shape:draw()
                if self._intersect_active or self._interact_active then
                    self._debug_state_overlay:draw()
                end
            end
            self._debug_shape_outline:draw()
        end
    end
end