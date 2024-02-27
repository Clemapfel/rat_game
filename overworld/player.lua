rt.settings.overworld.player = {
    radius = 32 / 2 - 1,
    mass = 0,
    velocity = 250,
    sprinting_velocity_factor = 2,
    acceleration_delay = 0.3, -- seconds
    deadzone = 0.05,

    is_player_key = "is_player",
    is_player_sensor_key = "is_player_sensor",
    player_instance_key = "instance",
}

--- @class ow.Player
ow.Player = meta.new_type("Player", ow.OverworldEntity, rt.Animation, function(scene, spawn_x, spawn_y)
    local out = meta.new(ow.Player, {
        _scene = scene,
        _world = scene._world,

        _radius = rt.settings.overworld.player.radius,
        _spawn_x = which(spawn_x, 0),
        _spawn_y = which(spawn_y, 0),

        _collider = {},  -- rt.CircleCollider
        _sensor = {},    -- rt.CircleCollider
        _sensor_active = false,
        _sensor_consumed = false,

        _debug_body = {},               -- rt.Circle
        _debug_body_outline = {},       -- rt.Circle
        _debug_velocity = {},           -- rt.Polygon
        _debug_velocity_outline = {},   -- rt.Polygon
        _debug_direction = {},          -- rt.Polygon
        _debug_direction_outline = {},  -- rt.Circle
        _debug_sensor = {},             -- rt.Circle
        _debug_sensor_outline = {},     -- rt.Circle

        _input = {},    -- rt.InputController
        _direction = 0, -- radians
        _direction_active = false,
        _is_sprinting = false,
        _velocity_magnitude = 0,
        _velocity_angle = 0, -- radians
        _movement_timer = 0, -- seconds
    })
    return out
end)

--- @override
function ow.Player:realize()
    local radius = self._radius
    self._input = rt.InputController(self)

    self._collider = rt.CircleCollider(
        self._world,
        rt.ColliderType.DYNAMIC,
        self._spawn_x,
        self._spawn_y,
        radius
    )

    self._sensor = rt.CircleCollider(self._world, rt.ColliderType.DYNAMIC, 0, 0, radius)

    local keys = rt.settings.overworld.player
    self._collider:add_userdata(keys.is_player_key, true)
    self._collider:add_userdata("instance", self)

    self._sensor:add_userdata(keys.is_player_sensor_key, true)
    self._sensor:add_userdata("instance", self)

    self._debug_body = rt.Circle(0, 0, radius)
    self._debug_body_outline = rt.Circle(0, 0, radius)
    self._debug_velocity = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0)
    self._debug_velocity_outline = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0)
    self._debug_direction = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0)
    self._debug_direction_outline = rt.Polygon(0, 0, 0, 0, 0, 0, 0, 0)
    self._debug_sensor = rt.Circle(0, 0, 1)
    self._debug_sensor_outline = rt.Circle(0, 0, 1)

    self._sensor:set_disabled(true)
    self._sensor:set_is_sensor(true)

    self._debug_body:set_is_outline(false)
    self._debug_body_outline:set_is_outline(true)
    self._debug_body:set_color(rt.Palette.PURPLE_5)
    self._debug_body_outline:set_color(rt.Palette.PURPLE_6)

    self._debug_velocity:set_color(rt.Palette.PURPLE_4)
    self._debug_velocity_outline:set_color(rt.Palette.PURPLE_6)
    self._debug_velocity_outline:set_is_outline(true)

    self._debug_direction:set_color(rt.Palette.PURPLE_3)
    self._debug_direction_outline:set_color(rt.Palette.PURPLE_6)
    self._debug_direction_outline:set_is_outline(true)

    local sensor_color = rt.RGBA(0.4, 0.4, 0.4, 1)
    self._debug_sensor_outline:set_color(sensor_color)
    self._debug_sensor_outline:set_is_outline(true)

    sensor_color.a = 0.25
    self._debug_sensor:set_color(sensor_color)
    self._debug_sensor:set_is_outline(false)

    self._collider:set_mass(rt.settings.overworld.player.mass)

    self._input = rt.add_input_controller(self)
    self._input:signal_connect("pressed", ow.Player._handle_button_pressed, self)
    self._input:signal_connect("released", ow.Player._handle_button_released, self)
    self._input:signal_connect("joystick", ow.Player._handle_joystick, self)

    self._world:signal_connect("update", ow.Player._on_physics_update, self)
    self._sensor:set_allow_sleeping(false)

    self:set_is_animated(true)
    self._is_realized = true

    self:set_position(self._spawn_x, self._spawn_y)
    return self
end

--- @overload
function ow.Player:draw()
    if self._is_realized then

        if self._scene:get_debug_draw_enabled() then
            self._debug_body:draw()
            self._debug_body_outline:draw()

            self._debug_velocity:draw()
            self._debug_velocity_outline:draw()

            self._debug_direction:draw()
            self._debug_direction_outline:draw()
        end

        if self._sensor_active == true then
            love.graphics.push()
            rt.graphics.set_blend_mode(rt.BlendMode.ADD)
            self._debug_sensor:draw()
            rt.graphics.set_blend_mode(rt.BlendMode.NORMAL)
            love.graphics.pop()
            self._debug_sensor_outline:draw()
        end
    end
end

function ow.Player._on_physics_update(_, self)
    if self._is_realized then
        local x, y = self._collider:get_centroid()
        self._sensor:set_centroid(rt.translate_point_by_angle(x, y, self._radius, self._direction))
        self:_update_velocity()
    end
end

--- @override
function ow.Player:update(delta)
    if not self._is_realized then return end

    if self._velocity_magnitude > rt.settings.overworld.player.deadzone then
        self._movement_timer = self._movement_timer + delta
    end

    if self._scene:get_debug_draw_enabled() then
        local x, y = self._collider:get_centroid()
        local max_velocity = rt.settings.overworld.player.velocity
        local velocity_x, velocity_y = self._collider:get_linear_velocity()
        local angle = rt.angle(velocity_x, velocity_y)

        self._debug_body:set_centroid(x, y)
        self._debug_body_outline:set_centroid(x, y)

        -- velocity indicator
        local radius = self._debug_body:get_radius()
        local velocity_magnitude = rt.magnitude(velocity_x, velocity_y)
        local magnitude_fraction = velocity_magnitude / max_velocity * radius
        local indicator_radius_fraction = 0.25
        local velocity_indicator_magnitude = clamp(magnitude_fraction, indicator_radius_fraction * radius, radius)

        local tip_x, tip_y = rt.translate_point_by_angle(x, y, velocity_indicator_magnitude, angle)

        local angle_offset = math.pi / 2
        local direction_triangle_radius = rt.settings.overworld.player.radius * indicator_radius_fraction
        local up_x, up_y = rt.translate_point_by_angle(x, y, direction_triangle_radius , angle - angle_offset)
        local down_x, down_y = rt.translate_point_by_angle(x, y, direction_triangle_radius, angle + angle_offset)
        local back_x, back_y = rt.translate_point_by_angle(x, y, direction_triangle_radius, angle - 2 * angle_offset)
        self._debug_velocity:resize(up_x, up_y, tip_x, tip_y, down_x, down_y, back_x, back_y)
        self._debug_velocity_outline:resize(up_x, up_y, tip_x, tip_y, down_x, down_y, back_x, back_y)

        -- direction indicator
        direction_triangle_radius = direction_triangle_radius * 0.5
        local direction_indicator_magnitude = 0.5 * radius
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

        local center_x, center_y = self._sensor:get_centroid()
        self._debug_sensor:resize(center_x, center_y, radius)
        self._debug_sensor_outline:resize(center_x, center_y, radius)
    end
end

--- @brief [internal]
function ow.Player:_update_velocity()
    local damping = clamp(0, 1, self._movement_timer / rt.settings.overworld.player.acceleration_delay)
    damping = clamp(0.3, rt.exponential_acceleration(damping))

    local x, y = rt.translate_point_by_angle(
        0, 0,
        self._velocity_magnitude * damping,
        self._velocity_angle
    )

    for collider in range(self._collider, self._sensor) do
        collider:set_linear_velocity(x, y)
    end

    if self._velocity_magnitude <= rt.settings.overworld.player.deadzone then
        self._movement_timer = 0
    else
        self:_set_sensor_active(false) -- disable sensor so it can't be carried while moving
    end
end

--- @brief [internal]
function ow.Player:_update_velocity_from_dpad()
    local up = ternary(self._input:is_down(rt.InputButton.UP), -1, 0)
    local right = ternary(self._input:is_down(rt.InputButton.RIGHT), 1, 0)
    local down = ternary(self._input:is_down(rt.InputButton.DOWN), 1, 0)
    local left = ternary(self._input:is_down(rt.InputButton.LEFT), -1, 0)

    local x, y = (left + right), (up + down)

    local angle = rt.angle(x, y)
    local target = rt.settings.overworld.player.velocity
    if self._is_sprinting then
        target = target * rt.settings.overworld.player.sprinting_velocity_factor
    end

    self._velocity_magnitude = rt.magnitude(x, y) * target
    self._velocity_angle = angle

    if x + y ~= 0 then
        self._direction = angle
    end
end

--- @brief [internal]
function ow.Player:_set_sensor_active(b)
    self._sensor_active = b
    self._sensor_consumed = false
    self._sensor:set_disabled(not b)
    self._sensor:set_linear_velocity(0, 0)
end

--- @bref [internal] called by ow.Trigger, makes it so the sensor can only trigger one object per button press
function ow.Player:_try_consume_sensor()
    local out = self._sensor_consumed == false
    self._sensor_consumed = true
    return out
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
        if self._is_sprinting then
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
    end
end

--- @brief
function ow.Player:get_bounds()
    local x, y = self._collider:get_position()
    local radius = self._radius
    return rt.AABB(x - radius, y - radius, 2 * radius, 2 * radius)
end

--- @brief
function ow.Player:get_has_focus()
    return self._is_realized
end

--- @brief
function ow.Player:set_position(x, y)
    if self._is_realized then
        self._collider:set_centroid(x, y)
        ow.Player._on_physics_update(0, self)
    else
        self._spawn_x = x
        self._spawn_y = y
    end
end