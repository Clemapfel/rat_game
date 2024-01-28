rt.settings.overworld.player = {
    radius = 50,
    velocity = 400
}

--- @class ow.Player
ow.Player = meta.new_type("Player", function(world)
    local radius = rt.settings.overworld.player.radius
    local out = meta.new(ow.Player, {
        _world = world,
        _collider = rt.CircleCollider(world, rt.ColliderType.DYNAMIC, 0, 0, radius),
        _shape = rt.Circle(0, 0, radius),
        _input = {}, -- rt.InputController,
        _input_direction = {}           -- Table<rt.Direction, Boolean>
    }, rt.Drawable, rt.Animation, rt.Widget)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", ow.Player._handle_button_pressed, out)
    out._input:signal_connect("released", ow.Player._handle_button_released, out)
    out._input:signal_connect("joystick", ow.Player._handle_joystick, out)

    for direction in range(rt.Direction.UP, rt.Direction.RIGHT, rt.Direction.DOWN, rt.Direction.LEFT) do
        out._input_direction[direction] = false
    end

    out:set_is_animated(true)
    return out
end)

--- @brief [internal]
function ow.Player:set_velocity(x, y)
    self._collider:set_linear_velocity(x, y)
end

--- @brief
--- @return Number, Number
function ow.Player:get_velocity()
    return self._collider:get_linear_velocity()
end

--- @brief [internal]
function ow.Player._handle_button_pressed(_, button, self)
    local left_velocity, y_velocity = 0, 0--self:get_velocity()
    local target_velocity = rt.settings.overworld.player.velocity

    if button == rt.InputButton.A then
    end

    if button == rt.InputButton.UP then
        self._input_direction[rt.Direction.UP] = true
        y_velocity = y_velocity - target_velocity
    end

    if button == rt.InputButton.RIGHT then
        self._input_direction[rt.Direction.RIGHT] = true
        x_velocity = x_velocity + target_velocity
    end

    if button == rt.InputButton.DOWN then
        self._input_direction[rt.Direction.DOWN] = true
        y_velocity = y_velocity + target_velocity
    end

    if button == rt.InputButton.LEFT then
        self._input_direction[rt.Direction.LEFT] = true
        x_velocity = x_velocity - target_velocity
    end
    self:set_velocity(x_velocity, y_velocity)
end

--- @brief [internal]
function ow.Player._handle_button_released(_, button, self)
    local x_velocity, y_velocity = self:get_velocity()
    local target_velocity = rt.settings.overworld.player.velocity

    if button == rt.InputButton.A then
    elseif button == rt.InputButton.UP then
        if self._input_direction[rt.Direction.UP] then
            y_velocity = 0
            self._input_direction[rt.Direction.UP] = false
        end
    elseif button == rt.InputButton.RIGHT then
        if self._input_direction[rt.Direction.RIGHT] then
            x_velocity = 0
            self._input_direction[rt.Direction.RIGHT] = false
        end
    elseif button == rt.InputButton.DOWN then
        if self._input_direction[rt.Direction.DOWN] then
            y_velocity = 0
            self._input_direction[rt.Direction.DOWN] = false
        end
    elseif button == rt.InputButton.LEFT then
        if self._input_direction[rt.Direction.LEFT] then
            x_velocity = 0
            self._input_direction[rt.Direction.LEFT] = false
        end
    end
    self:set_velocity(x_velocity, y_velocity)
end

--- @brief [internal]
function ow.Player._handle_joystick(_, x, y, self)

end

--- @overload
function ow.Player:draw()
    self._shape:draw()
end

--- @overload
function ow.Player:update(delta)
    local x, y = self._collider:get_centroid()
    self._shape:set_centroid(x, y)
end
