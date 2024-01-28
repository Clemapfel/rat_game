rt.settings.battle_animation.enemy_died = {
    duration = 10,
    tile_size = 10 -- n particles: tile_size^2
}

--- @class
--- @param targets Table<rt.Widget>
bt.Animation.ENEMY_DIED = meta.new_type("ENEMY_DIED", function(targets)
    local n_targets = sizeof(targets)
    local out = meta.new(bt.Animation.ENEMY_DIED, {
        _targets = targets,
        _n_targets = n_targets,
        _snapshots = {}, -- Table<rt.SnapshotLayout>

        _grounds = {},          -- Table<rt.LineCollider>
        _particles = {},        -- Table<Table<rt.RectangleCollider>>
        _particle_shapes = {},  -- Table<Table<rt.VertexShape>>
        _particle_width = 1,
        _particle_height = 1,
        _impulse_send = {},     -- Table<Boolean>

        _shake_paths = {}, -- Table<rt.Spline>
        _elapsed = 0,
    }, rt.StateQueueState)

    for i = 1, out._n_targets do
        local snapshot = rt.SnapshotLayout()
        table.insert(out._snapshots, snapshot)
    end
    return out
end)

bt.Animation.ENEMY_DIED._world = rt.PhysicsWorld()

-- @overload
function bt.Animation.ENEMY_DIED:start()
    self._grounds = {}
    self._particles = {}
    self._world = rt.PhysicsWorld(0, 0)

    self._impulse_send = table.rep(false, self._n_targets)

    for i = 1, self._n_targets do
        local target = self._targets[i]
        local snapshot = self._snapshots[i]
        local bounds = target:get_bounds()
        snapshot:realize()
        snapshot:fit_into(bounds)

        target:set_is_visible(true)
        snapshot:snapshot(target)
        target:set_is_visible(false)

        table.insert(self._grounds, rt.LineCollider(self._world, rt.ColliderType.STATIC,
            bounds.x - 1, bounds.y + bounds.height + 1,
                bounds.x + bounds.width + 1, bounds.y + bounds.height + 1
        ))

        local particles = {}
        local particle_shapes = {}
        local tile_size = rt.settings.battle_animation.enemy_died.tile_size
        local w, h = bounds.width / tile_size, bounds.height / tile_size

        self._particle_width = w
        self._particle_height = h
        for y_i = 0, tile_size - 1 do
            for x_i = 0, tile_size - 1 do
                local mx, my = 1 / 6, 1 / 6
                local x = bounds.x + x_i / tile_size * bounds.width
                local y = bounds.y + y_i / tile_size * bounds.height
                local particle = rt.RectangleCollider(self._world, rt.ColliderType.DYNAMIC,
                        x + mx, y + my, w - 2 * mx, h - 2 * my
                )
                particle:set_restitution(0.8)
                particle:set_mass(1)
                particle:set_disabled(true)
                table.insert(particles, particle)

                local shape = rt.VertexRectangle(x, y, w, h)
                shape:set_texture(snapshot._canvas)
                shape:set_texture_rectangle(rt.AABB(
                    x_i / tile_size, y_i / tile_size, 1 / tile_size, 1 / tile_size
                ))
                table.insert(particle_shapes, shape)
            end
        end
        table.insert(self._particles, particles)
        table.insert(self._particle_shapes, particle_shapes)

        local vertices = {0, 0}
        local n_shakes = 7
        for _ = 1, n_shakes do
            for p in range(-1, 0, 1, 0, 0, 0) do
                table.insert(vertices, p)
            end
        end
        table.insert(self._shake_paths, rt.Spline(vertices))
    end
end

--- @overload
function bt.Animation.ENEMY_DIED:update(delta)
    local duration = rt.settings.battle_animation.enemy_died.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    local explosion_time = 2
    local explosion_delay_between_targets = 0.8
    local impulse_strength = 5
    local max_gravity = 2000

    local left_screen = true
    for i = 1, self._n_targets do

        -- pre-explosion shake
        local shake_offset_x, shake_offset_y = 0, 0
        if fraction * duration < explosion_time then
            local shake_fraction = (fraction * duration) / explosion_time
            shake_offset_x, shake_offset_y = self._shake_paths[i]:at(explosion_time * rt.exponential_acceleration(shake_fraction))
            local bounds = self._targets[i]:get_bounds()

            local shake_amplitude = 0.05
            shake_offset_x = shake_offset_x * bounds.width * shake_amplitude
            shake_offset_y = shake_offset_y * bounds.height * shake_amplitude
        end

        -- update particle from physics sim
        for particle_i = 1, #self._particles[i] do
            local particle = self._particles[i][particle_i]
            local shape = self._particle_shapes[i][particle_i]

            local x, y = particle:get_centroid()
            x = x - self._particle_width * 0.5 + shake_offset_x
            y = y - self._particle_height * 0.5 + shake_offset_y

            local w, h = self._particle_width, self._particle_height

            shape:set_vertex_position(1, x + 0, y + 0)
            shape:set_vertex_position(2, x + w, y + 0)
            shape:set_vertex_position(3, x + w, y + h)
            shape:set_vertex_position(4, x + 0, y + h)

            if y < love.graphics.getHeight() then
                left_screen = false
            else
                particle:set_disabled(true) -- disable particles that leave the screen to ease load on simulation
            end
        end

        -- after delay, explode all particles, animation waits for the last particle to leave the screen falling
        if fraction * duration > explosion_time + (i-1) * explosion_delay_between_targets and not self._impulse_send[i] then
            self._grounds[i]:set_disabled(true)
            local bounds = self._targets[i]:get_bounds()
            local center_x, center_y = bounds.x + 0.5 * bounds.width, bounds.y + 0.5 * bounds.height
            for particle_i = 1, #self._particles[i] do
                local particle = self._particles[i][particle_i]
                local x, y = particle:get_centroid()
                particle:set_disabled(false)
                particle:apply_linear_impulse(
                    rt.random.number(1, 2) * impulse_strength * (x - center_x),
                    rt.random.number(1, 2) * impulse_strength * (y - center_y)
                )
            end
            self._impulse_send[i] = true
        end
    end

    if fraction * duration > explosion_time then
        self._world:update(0.5 * delta, 0, 0)
        self._world:set_gravity(0,  clamp(rt.exponential_acceleration(3 * fraction) * max_gravity, 0, 1.5 * max_gravity))
    end

    return not left_screen -- last particle left the screen
end

--- @overload
function bt.Animation.ENEMY_DIED:finish()
    for i = 1, self._n_targets do
        local target = self._targets[i]
        target:set_is_visible(true)

        self._grounds[i]:destroy()
        for _, particle in pairs(self._particles[i]) do
            particle:destroy()
        end
    end
end

--- @overload
function bt.Animation.ENEMY_DIED:draw()
    for i = 1, self._n_targets do
        for _, shape in pairs(self._particle_shapes[i]) do
            shape:draw()
        end
    end
end