rt.settings.overworld.player = {
    radius = 32 / 2.5,
    mass = 0,
    velocity = 400,
    sprinting_velocity_factor = 2,
    acceleration_delay = 5, -- seconds
    deadzone = 0.05
}

--- @class ow.Player
ow.Player = meta.new_type("Player", function(world)
    local radius = rt.settings.overworld.player.radius
    local out = meta.new(ow.Player, {
        _world = world,
        _collider = rt.CircleCollider(world, rt.ColliderType.DYNAMIC, 0, 0, radius),
        _sensor = rt.CircleCollider(world, rt.ColliderType.DYNAMIC, 0, 0, radius),
        _sensor_active = false,

        _debug_body = rt.Circle(0, 0, radius),
        _debug_body_outline = rt.Circle(0, 0, radius),

        _debug_velocity = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0),
        _debug_velocity_outline = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0),
        _debug_direction = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0),
        _debug_direction_outline = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0),

        _debug_sensor = rt.Circle(0, 0, 1),
        _debug_sensor_outline = rt.Circle(0, 0, 1),

        _input = {}, -- rt.InputController
        _direction = 0, -- radians
        _direction_active = false,
        _is_sprinting = false,

        _velocity_magnitude = 0,
        _velocity_angle = 0, -- radians
    }, rt.Drawable, rt.Animation, rt.Widget)

    out._sensor:set_disabled(true)
    out._sensor:set_is_sensor(true)

    out._debug_body:set_is_outline(false)
    out._debug_body_outline:set_is_outline(true)
    out._debug_body:set_color(rt.Palette.PURPLE_5)
    out._debug_body_outline:set_color(rt.Palette.PURPLE_6)

    out._debug_velocity:set_color(rt.Palette.PURPLE_4)
    out._debug_velocity_outline:set_color(rt.Palette.PURPLE_6)
    out._debug_velocity_outline:set_is_outline(true)

    out._debug_direction:set_color(rt.Palette.PURPLE_3)
    out._debug_direction_outline:set_color(rt.Palette.PURPLE_6)
    out._debug_direction_outline:set_is_outline(true)

    local sensor_color = rt.RGBA(0.4, 0.4, 0.4, 1)
    out._debug_sensor_outline:set_color(sensor_color)
    out._debug_sensor_outline:set_is_outline(true)

    sensor_color.a = 0.25
    out._debug_sensor:set_color(sensor_color)
    out._debug_sensor:set_is_outline(false)

    out._collider:set_mass(rt.settings.overworld.player.mass)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", ow.Player._handle_button_pressed, out)
    out._input:signal_connect("released", ow.Player._handle_button_released, out)
    out._input:signal_connect("joystick", ow.Player._handle_joystick, out)

    out._world:signal_connect("update", ow.Player._on_physics_update, out)
    out:set_is_animated(true)

    out._sensor:set_allow_sleeping(false)

    -- sensor: triggers InteractTrigger
    out._sensor:signal_connect("contact_begin", function(_, other, self)
        if other ~= out._collider then -- prevent sensor and player colliding
            local instance = other:get_userdata("instance")
            if meta.isa(instance, ow.InteractTrigger) then
                if self._sensor_active then
                    instance:signal_emit("activate", self)
                    self._sensor_active = false
                end
            end
        end
    end, out)

    -- body: triggers IntersectTrigger
    local on_intersect = function(_, other, self)
        if other ~= out._sensor then
            local instance = other:get_userdata("instance")
            if meta.isa(instance, ow.IntersectTrigger) then
                instance:signal_emit("activate", self)
            end
        end
    end
    out._collider:signal_connect("contact_begin", on_intersect, out)
    out._collider:signal_connect("contact_end", on_intersect, out)

    return out
end)

--- @brief [internal]
function ow.Player._on_contact(_, other, self)

end

--- @brief [internal]
function ow.Player:_set_sensor_active(b)
    self._sensor_active = b
    self._sensor:set_disabled(not b)
    self._sensor:set_linear_velocity(0, 0)
end

--- @brief [internal]
function ow.Player:_update_velocity()
    local x, y = rt.translate_point_by_angle(0, 0, self._velocity_magnitude, self._velocity_angle)
    self._collider:set_linear_velocity(x, y)
    self._sensor:set_linear_velocity(x, y)
end

--- @brief
--- @return Number, Number
function ow.Player:get_velocity()
    return self._collider:get_linear_velocity()
end

--- @brief
function ow.Player:set_is_sprinting(b)
    self._is_sprinting = b
end

--- @brief
function ow.Player:get_is_sprinting()
    return self._is_sprinting
end

function ow.Player:_update_velocity_from_dpad()
    local up = ternary(self._input:is_down(rt.InputButton.UP), -1, 0)
    local right = ternary(self._input:is_down(rt.InputButton.RIGHT), 1, 0)
    local down = ternary(self._input:is_down(rt.InputButton.DOWN), 1, 0)
    local left = ternary(self._input:is_down(rt.InputButton.LEFT), -1, 0)

    local x, y = (left + right), (up + down)

    local angle = rt.angle(x, y)
    local target = rt.settings.overworld.player.velocity
    if self:get_is_sprinting() then
        target = target * rt.settings.overworld.player.sprinting_velocity_factor
    end

    self._velocity_magnitude = rt.magnitude(x, y) * target
    self._velocity_angle = angle

    if x + y ~= 0 then
        self._direction = angle
    end

    self:_update_velocity()
end


--- @brief [internal]
function ow.Player._handle_button_pressed(_, button, self)
    if button == rt.InputButton.A then
        self:_set_sensor_active(true)
    end

    if button == rt.InputButton.B then
        self._is_sprinting = true
    end

    if button == rt.InputButton.UP or button == rt.InputButton.RIGHT or button == rt.InputButton.DOWN or button == rt.InputButton.LEFT then
        self:_update_velocity_from_dpad()
    end
end

--- @brief [internal]
function ow.Player._handle_button_released(_, button, self)

    if button == rt.InputButton.A then
        self:_set_sensor_active(false)
    end

    if button == rt.InputButton.B then
        self._is_sprinting = false
    end

    if button == rt.InputButton.UP or button == rt.InputButton.RIGHT or button == rt.InputButton.DOWN or button == rt.InputButton.LEFT then
        self:_update_velocity_from_dpad()
    end
end

--- @brief [internal]
function ow.Player._handle_joystick(_, x, y, which, self)

    -- if right joystick is not held, left overwrites direction, otherwise right always decides direction
    local magnitude = rt.magnitude(x, y)
    local deadzone = rt.settings.overworld.player.deadzone

    if which == rt.JoystickPosition.RIGHT then
        if magnitude > deadzone then
            self._direction = rt.angle(x, y)
            self._direction_active = true
        else
            self._direction_active = false
        end
    end

    if which == rt.JoystickPosition.LEFT then
        local target = rt.settings.overworld.player.velocity
        if self:get_is_sprinting() then
            target = target * rt.settings.overworld.player.sprinting_velocity_factor
        end

        local angle = rt.angle(x, y)
        if self._direction_active == false and magnitude > deadzone then
            self._direction = angle
        end

        self._velocity_magnitude = magnitude * target
        self._velocity_angle = angle

        if magnitude > 0.01 then
            self._direction = angle
        end
        self:_update_velocity()
    end
end

--- @overload
function ow.Player:draw()
    self._debug_body:draw()
    self._debug_body_outline:draw()

    self._debug_velocity:draw()
    self._debug_velocity_outline:draw()

    self._debug_direction:draw()
    self._debug_direction_outline:draw()

    if self._sensor_active == true then
        love.graphics.push()
        love.graphics.setBlendMode("add", "premultiplied")
        self._debug_sensor:draw()
        love.graphics.setBlendMode("alpha")
        love.graphics.pop()
        self._debug_sensor_outline:draw()
    end
end

--- @brief
function ow.Player:get_position()
    return self._collider:get_centroid()
end

--- @brief
function ow.Player:set_position(x, y)
    self._collider:set_centroid(x, y)
    self._on_physics_update(_, self)
end

--- @brief [internal]
function ow.Player._on_physics_update(_, self)
    local x, y = self._collider:get_centroid()
    self._debug_body:set_centroid(x, y)
    self._debug_body_outline:set_centroid(x, y)

    -- velocity indicator
    local max_velocity = rt.settings.overworld.player.velocity
    local velocity_x, velocity_y = self:get_velocity()
    local angle = rt.angle(velocity_x, velocity_y)

    local radius = self._debug_body:get_radius()
    local velocity_magnitude = rt.magnitude(velocity_x, velocity_y)
    local magnitude_fraction = velocity_magnitude / max_velocity * radius
    local indicator_radius_fraction = 0.25
    local velocity_indicator_magnitude = clamp(magnitude_fraction, indicator_radius_fraction * radius, radius)

    local tip_x, tip_y = rt.translate_point_by_angle(x, y, velocity_indicator_magnitude, angle)

    local angle_offset = rt.degrees(90):as_radians()
    local direction_triangle_radius = rt.settings.overworld.player.radius * indicator_radius_fraction
    local up_x, up_y = rt.translate_point_by_angle(x, y, direction_triangle_radius , angle - angle_offset)
    local down_x, down_y = rt.translate_point_by_angle(x, y, direction_triangle_radius, angle + angle_offset)
    local back_x, back_y = rt.translate_point_by_angle(x, y, direction_triangle_radius, angle - 2 * angle_offset)
    self._debug_velocity:resize(up_x, up_y, tip_x, tip_y, down_x, down_y, back_x, back_y)
    self._debug_velocity_outline:resize(up_x, up_y, tip_x, tip_y, down_x, down_y, back_x, back_y)

    -- direction indicator
    direction_triangle_radius = direction_triangle_radius * 0.5
    local direction_indicator_magnitude = 0.5 * radius--clamp(velocity_indicator_magnitude, 0.5 * radius)
    tip_x, tip_y = rt.translate_point_by_angle(
            x, y,
            direction_indicator_magnitude,
            self._direction
    )

    up_x, up_y = rt.translate_point_by_angle(x, y, direction_triangle_radius , self._direction - angle_offset)
    down_x, down_y = rt.translate_point_by_angle(x, y, direction_triangle_radius, self._direction + angle_offset)
    back_x, back_y = rt.translate_point_by_angle(x, y, direction_triangle_radius, self._direction - 2 * angle_offset)
    self._debug_direction:resize(up_x, up_y, tip_x, tip_y, down_x, down_y, back_x, back_y)
    self._debug_direction_outline:resize(up_x, up_y, tip_x, tip_y, down_x, down_y, back_x, back_y)

    -- sensor location
    self._sensor:set_centroid(rt.translate_point_by_angle(x, y, radius, self._direction))

    local center_x, center_y = self._sensor:get_centroid()
    self._debug_sensor:resize(center_x, center_y, radius)
    self._debug_sensor_outline:resize(center_x, center_y, radius)

end

--- @overload
function ow.Player:update(delta)

end
