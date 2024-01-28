rt.settings.overworld.player = {
    radius = 50,
    mass = 0,
    velocity = 400,
    sprinting_velocity_factor = 2,
    acceleration_delay = 5, -- seconds
}

--- @class ow.Player
ow.Player = meta.new_type("Player", function(world)
    local radius = rt.settings.overworld.player.radius
    local out = meta.new(ow.Player, {
        _world = world,
        _collider = rt.CircleCollider(world, rt.ColliderType.DYNAMIC, 0, 0, radius),
        _debug_body = rt.Circle(0, 0, radius),
        _debug_body_outline = rt.Circle(0, 0, radius),
        _debug_direction = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0),
        _debug_direction_outline = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0),

        _input = {}, -- rt.InputController
        _direction = rt.radians(0),
        _is_sprinting = false,
        _acceleration_timer = 0
    }, rt.Drawable, rt.Animation, rt.Widget)

    out._debug_body:set_is_outline(false)
    out._debug_body_outline:set_is_outline(true)
    out._debug_body:set_color(rt.Palette.PURPLE_5)
    out._debug_body_outline:set_color(rt.Palette.PURPLE_6)
    out._debug_direction:set_color(rt.Palette.PURPLE_3)
    out._debug_direction_outline:set_color(rt.Palette.PURPLE_6)
    out._debug_direction_outline:set_is_outline(true)

    out._collider:set_mass(rt.settings.overworld.player.mass)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", ow.Player._handle_button_pressed, out)
    out._input:signal_connect("released", ow.Player._handle_button_released, out)
    out._input:signal_connect("joystick", ow.Player._handle_joystick, out)

    out._world:signal_connect("update", ow.Player._on_physics_update, out)
    out:set_is_animated(true)

    return out
end)

--- @brief [internal]
function ow.Player:set_velocity(x, y)

    self._collider:set_linear_velocity(x, y)

    local eps = 0.001
    if math.abs(x) < eps and math.abs(y) < eps then
        self._acceleration_timer = 0
        self._direction = rt.angle(x, y)
    end
end

--- @brief
--- @return Number, Number
function ow.Player:get_velocity()
    return self._collider:get_linear_velocity()
end

--- @brief [internal]
function ow.Player._handle_button_pressed(_, button, self)
    if button == rt.InputButton.A then
    end

    -- movement
    --if button == rt.InputButton.L or button == rt.InputButton.R then

    local sprinting_factor = rt.settings.overworld.player.sprinting_velocity_factor
    if button == rt.InputButton.A then
        self._is_sprinting = true
        local x, y = self:get_velocity()
        self:set_velocity(x * sprinting_factor, y * sprinting_factor)
    end

    local up, right, down, left = 0, 0, 0, 0
    local target = rt.settings.overworld.player.velocity
    if self._is_sprinting then target = target * sprinting_factor end

    if button == rt.InputButton.UP then
        up = target
    end

    if button == rt.InputButton.RIGHT then
        right = target
    end

    if button == rt.InputButton.DOWN then
        down = target
    end

    if button == rt.InputButton.LEFT then
        left = target
    end

    local x_velocity, y_velocity = self:get_velocity()
    self:set_velocity(
        x_velocity + right - left,
        y_velocity + down - up
    )
end

--- @brief [internal]
function ow.Player._handle_button_released(_, button, self)

    if button == rt.InputButton.A then
    end

    -- movement
    local sprinting_factor = rt.settings.overworld.player.sprinting_velocity_factor
    if button == rt.InputButton.A then
        self._is_sprinting = false
        local x, y = self:get_velocity()
        self:set_velocity(x / sprinting_factor, y / sprinting_factor)
    end

    local up, right, down, left = 0, 0, 0, 0
    local target = rt.settings.overworld.player.velocity
    if self._is_sprinting then target = target * sprinting_factor end

    if button == rt.InputButton.UP then
        up = -1 * target
    end

    if button == rt.InputButton.RIGHT then
        right = -1 * target
    end

    if button == rt.InputButton.DOWN then
        down = -1 * target
    end

    if button == rt.InputButton.LEFT then
        left = -1 * target
    end

    local x_velocity, y_velocity = self:get_velocity()
    self:set_velocity(x_velocity + right - left, y_velocity + down - up)
end

--- @brief [internal]
function ow.Player._handle_joystick(_, x, y, which, self)

    if which == rt.JoystickPosition.LEFT then
        local target = rt.settings.overworld.player.velocity
        if self._is_sprinting then
            target = target * rt.settings.overworld.player.sprinting_velocity_factor
        end
        self:set_velocity(target * x, target * y)
    elseif which == rt.JoystickPosition.RIGHT then
        local new_direction = rt.angle(x, y)
        local magnitude = rt.magnitude(self:get_velocity())
    end
end

--- @overload
function ow.Player:draw()
    self._debug_body:draw()
    self._debug_body_outline:draw()
    self._debug_direction:draw()
    self._debug_direction_outline:draw()
end

--- @brief [internal]
function ow.Player._on_physics_update(_, self)
    local x, y = self._collider:get_centroid()
    self._debug_body:set_centroid(x, y)
    self._debug_body_outline:set_centroid(x, y)

    -- direction indicator: 4-vertex polygon pointing in direction of velocity
    local max_velocity = rt.settings.overworld.player.velocity
    local velocity_x, velocity_y = self:get_velocity()
    local angle = rt.angle(velocity_x, velocity_y)

    local radius = self._debug_body:get_radius()
    local velocity_magnitude = rt.magnitude(velocity_x, velocity_y)
    local magnitude_fraction = velocity_magnitude / max_velocity * radius
    local indicator_radius_fraction = 0.25
    local tip_x, tip_y = rt.translate_point_by_angle(x, y,  clamp(magnitude_fraction, indicator_radius_fraction * radius + 10), angle)

    local angle_offset = rt.degrees(90):as_radians()
    local direction_triangle_radius = rt.settings.overworld.player.radius * indicator_radius_fraction
    local up_x, up_y = rt.translate_point_by_angle(x, y, direction_triangle_radius , angle - angle_offset)
    local down_x, down_y = rt.translate_point_by_angle(x, y, direction_triangle_radius, angle + angle_offset)
    local back_x, back_y = rt.translate_point_by_angle(x, y, direction_triangle_radius, angle - 2 * angle_offset)
    self._debug_direction:resize(up_x, up_y, tip_x, tip_y, down_x, down_y, back_x, back_y)
    self._debug_direction_outline:resize(up_x, up_y, tip_x, tip_y, down_x, down_y, back_x, back_y)
end

--- @overload
function ow.Player:update(delta)

    local x_velocity, y_velocity = self:get_velocity()
    local eps = 0.01
    if math.abs(x_velocity) > eps or math.abs(y_velocity) > eps then
        self._acceleration_timer = self._acceleration_timer + delta
        local duration = rt.settings.overworld.player.acceleration_delay
        local fraction = clamp(self._acceleration_timer / duration, 0, 1)
        local max_dampening = 0.01
        --self._collider:set_linear_dampening(fraction * max_dampening, fraction * max_dampening)
    else
        self._acceleration_timer = 0
    end

end
