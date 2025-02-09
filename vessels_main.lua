require "include"

--[[
for each point, pre-generate the indices of it's branches recursively

]]--

self = _G
_points = {}
_texture = nil

_initial_radius = 10
_n_outer_vertices = 16
_n_start_points = 1
_step_size = 1 / 60

_velocity_perturbation_magnitude = 0.01 * math.pi
_positional_speed = 100
_mass_decay_speed = 0.2
_inertia = 0.985

_split_distance = 200
_split_cooldown = 50

_point_new = function(px, py, vx, vy, av, mass)
    return {
        radius = self._initial_radius,
        position_x = px,
        position_y = py,
        velocity_x = vx,
        velocity_y = vy,
        angular_velocity = av,
        distance_since_split = 0,
        mass = mass,
        hue = rt.random.number(0, 1),
    }
end

_point_draw = function(point)
    love.graphics.setColor(rt.color_unpack(rt.lcha_to_rgba(rt.LCHA(0.8, 1, point.mass, 1))))
    love.graphics.circle("fill",
        point.position_x, point.position_y,
        point.mass * point.radius, point.mass * point.radius,
        self._n_outer_vertices
    )
end

love.load = function()
    local width, height = 1000, 1000
    love.window.setMode(width, height, {
        msaa = 4
    })
    love.graphics.present()

    self._texture = rt.RenderTexture(width, height, 4)
    self._texture:bind()
    love.graphics.clear(0, 0, 0, 1)
    self._texture:unbind()

    local up = self._point_new(
        0.5 * width, 0.5 * height,
        0, -1,
        0,
        1
    )

    local down = self._point_new(
        0.5 * width, 0.5 * height,
        0, 1,
        0,
        1
    )

    local left = self._point_new(
        0.5 * width, 0.5 * height,
        -1, 0,
        0,
        1
    )

    local right = self._point_new(
        0.5 * width, 0.5 * height,
        1, 0,
        0,
        1
    )
    self._points = {
        up, down, left, right
    }


    local mass_duration = 1 / _mass_decay_speed
    local distance = mass_duration * _positional_speed
    local n_branches = distance / _split_cooldown

    local n = sizeof(self._points)
    for i = 1, n_branches do
        n = n + n * 2
    end

    dbg("predicted n_points: ", n)
end

function rotate(x, y, angle)
    local cos_angle = math.cos(angle)
    local sin_angle = math.sin(angle)

    local new_x = x * cos_angle + y * sin_angle
    local new_y = -x * sin_angle + y * cos_angle

    return new_x, new_y
end

local elapsed = 0
love.update = function(delta)
    if not love.keyboard.isDown("space") then return end
    elapsed = elapsed + delta
    while elapsed > self._step_size do
        local to_remove = {}
        for i, point in ipairs(self._points) do
            local angle = love.math.randomNormal(2, 0)
            angle = angle * 2 * self._velocity_perturbation_magnitude

            -- Apply inertia to angular velocity
            point.angular_velocity = point.angular_velocity * _inertia + angle * (1 - _inertia)

            point.velocity_x, point.velocity_y = rotate(point.velocity_x, point.velocity_y, point.angular_velocity)
            local step = self._step_size * _positional_speed

            point.position_x = point.position_x + point.velocity_x * step
            point.position_y = point.position_y + point.velocity_y * step

            point.distance_since_split = point.distance_since_split + math.sqrt((point.velocity_x * step)^2 + (point.velocity_y * step)^2)

            step = self._step_size * _mass_decay_speed
            point.mass = point.mass - step
            if point.mass <= 0 then
                table.insert(to_remove, i)
            else
                point.distance_since_split = point.distance_since_split + math.sqrt((point.velocity_x * step)^2, (point.velocity_y * step)^2)

                if point.distance_since_split > _split_cooldown then
                    local should_split = love.math.random(0, 1)
                    if should_split < math.max(point.distance_since_split - point.mass * _split_cooldown, 0) / _split_distance then
                        local n_splits = rt.random.integer(3, 3)
                        point.distance_since_split = 0

                        local angles = {}
                        local fan = math.pi / 2
                        if n_splits == 2 then
                            local new_vx1, new_vy1 = rotate(point.velocity_x, point.velocity_y, -1 * fan / 2)
                            point.velocity_x, point.velocity_y = new_vx1, new_vy1

                            local new_vx2, new_vy2 = rotate(point.velocity_x, point.velocity_y, fan / 2)
                            table.insert(self._points, self._point_new(
                                point.position_x,
                                point.position_y,
                                new_vx2,
                                new_vy2,
                                point.angular_velocity,
                                point.mass
                            ))
                        else
                            local new_vx2, new_vy2 = rotate(point.velocity_x, point.velocity_y, -1 * fan / 3)
                            table.insert(self._points, self._point_new(
                                point.position_x,
                                point.position_y,
                                new_vx2,
                                new_vy2,
                                point.angular_velocity,
                                point.mass
                            ))

                            new_vx2, new_vy2 = rotate(point.velocity_x, point.velocity_y, fan / 3)
                            table.insert(self._points, self._point_new(
                                point.position_x,
                                point.position_y,
                                new_vx2,
                                new_vy2,
                                point.angular_velocity,
                                point.mass
                            ))
                        end
                    end
                end
            end
        end

        for i in values(to_remove) do
            table.remove(self._points, i)
        end

        self._texture:bind()
        for point in values(self._points) do
            self._point_draw(point)
        end
        self._texture:unbind()

        elapsed = elapsed - self._step_size
    end
end

love.draw = function()
    self._texture:draw(0, 0)
    love.graphics.printf(love.timer.getFPS(), 5, 5, POSITIVE_INFINITY)
end

love.keypressed = function(which)
    if which == "x" then love.load() end
end

love.keyreleased = function(which)
    dbg("actual n_points: ", sizeof(self._points))
end