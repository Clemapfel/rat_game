rt.settings.overworld.player = {
    radius = 50,
    velocity = 50
}

ow._world = rt.PhysicsWorld(0, 0)

--- @class ow.Player
ow.Player = meta.new_type("Player", function()
    local radius = rt.settings.overworld.player.radius
    local out = meta.new(ow.Player, {
        _collider = rt.CircleCollider(ow._world,0, 0, radius),
        _shape = rt.Circle(0, 0, radius),
        _input = {}, -- rt.InputController
    }, rt.Drawable, rt.Animation)

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", ow.Player._handle_button_pressed, out)
    out._input:signal_connect("released", ow.Player._handle_button_released, out)
    out._input:signal_connect("joystick", ow.Player._handle_joystick, out)
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
    local x_velocity, y_velocity = self:get_velocity()
    local target_velocity = rt.settings.overworld.player.velocity

    if button == rt.InputButton.A then
    elseif button == rt.InputButton.UP then
        y_velocity = -1 * target_velocity
    elseif button == rt.InputButton.RIGHT then
        x_velocity = 1 * target_velocity
    elseif button == rt.InputButton.DOWN then
        y_velocity = 1 * target_velocity
    elseif button == rt.InputButton.LEFT then
        x_velocity = -1 * target_velocity
    end
    self:set_velocity(x_velocity, y_velocity)
end

--- @brief [internal]
function ow.Player._handle_button_released(_, button, self)
    local x_velocity, y_velocity = self:get_velocity()
    local target_velocity = rt.settings.overworld.player.velocity

    if button == rt.InputButton.A then
    elseif button == rt.InputButton.UP then
        y_velocity = 0
    elseif button == rt.InputButton.RIGHT then
        x_velocity = 0
    elseif button == rt.InputButton.DOWN then
        y_velocity = 0
    elseif button == rt.InputButton.LEFT then
        x_velocity = 0
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
end