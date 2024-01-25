rt.settings.enemy_disappeared_animation = {
    duration = 10,
    tile_size = 10
}

--- @class
--- @param targets Table<rt.Widget>
bt.EnemyDisappearedAnimation = meta.new_type("EnemyDisappearedAnimation", function(targets)
    local out = meta.new(bt.EnemyDisappearedAnimation, {
        _targets = targets,
        _n_targets = sizeof(targets),
        _snapshots = {}, -- Table<rt.SnapshotLayout>

        _grounds = {},          -- Table<rt.LineCollider>
        _particles = {},        -- Table<Table<rt.RectangleCollider>>
        _particle_shapes = {},  -- Table<Table<rt.VertexShape>>
        _particle_width = 1,
        _particle_height = 1,
        _impulse_send = false,

        _elapsed = 0,
    }, rt.StateQueueState)

    for i = 1, out._n_targets do
        local snapshot = rt.SnapshotLayout()
        table.insert(out._snapshots, snapshot)
    end
    return out
end)

bt.EnemyDisappearedAnimation._world = rt.PhysicsWorld()

-- @overload
function bt.EnemyDisappearedAnimation:start()
    self._grounds = {}
    self._particles = {}
    self._world = rt.PhysicsWorld(0, 0)

    self._impulse_send = false

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
        local tile_size = rt.settings.enemy_disappeared_animation.tile_size
        local w, h = bounds.width / tile_size, bounds.height / tile_size
        self._particle_width = w
        self._particle_height = h
        for y_i = 0, tile_size - 1 do
            for x_i = 0, tile_size - 1 do
                local x = bounds.x + x_i / tile_size * bounds.width
                local y = bounds.y + y_i / tile_size * bounds.height
                local particle = rt.RectangleCollider(self._world, rt.ColliderType.DYNAMIC,
                        x, y, w, h
                )
                particle:set_restitution(1)
                particle:set_mass(1)
                table.insert(particles, particle)

                local shape = rt.VertexRectangle(x, y, w, h)
                --shape:set_color(rt.HSVA(rt.random.number(0, 1), 1, 1, 1))
                shape:set_texture(snapshot._canvas)
                shape:set_texture_rectangle(rt.AABB(
                    x_i / tile_size, y_i / tile_size, 1 / tile_size, 1 / tile_size
                ))
                table.insert(particle_shapes, shape)
            end
        end
        table.insert(self._particles, particles)
        table.insert(self._particle_shapes, particle_shapes)
    end
end

--- @overload
function bt.EnemyDisappearedAnimation:update(delta)
    local duration = rt.settings.enemy_disappeared_animation.duration

    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    local left_screen = true
    for i = 1, self._n_targets do
        for particle_i = 1, #self._particles[i] do
            local particle = self._particles[i][particle_i]
            local shape = self._particle_shapes[i][particle_i]

            local x, y = particle:get_center_of_mass()
            x = x - self._particle_width * 0.5
            y = y - self._particle_height * 0.5

            local w, h = self._particle_width, self._particle_height

            shape:set_vertex_position(1, x + 0, y + 0)
            shape:set_vertex_position(2, x + w, y + 0 )
            shape:set_vertex_position(3, x + w, y + h)
            shape:set_vertex_position(4, x + 0, y + h)

            if y < love.graphics.getHeight() then
                left_screen = false
            end
        end
    end

    local impulse_strength = 5
    local max_gravity = 2000

    if fraction * duration > 2 and not self._impulse_send then
        for i = 1, self._n_targets do
            self._grounds[i]:set_disabled(true)
            local bounds = self._targets[i]:get_bounds()
            local center_x, center_y = bounds.x + 0.5 * bounds.width, bounds.y + 0.5 * bounds.height
            for _, particle in pairs(self._particles[i]) do
                local x, y = particle:get_center_of_mass()
                particle:apply_linear_impulse(
                    rt.random.number(1, 2) * impulse_strength * (x - center_x),
                    rt.random.number(1, 2) * impulse_strength * (y - center_y)
                )
            end
        end
        self._impulse_send = true
    end

    self._world:update(0.5 * delta)
    self._world:set_gravity(0,  rt.exponential_acceleration(3 * fraction) * max_gravity)
    return not left_screen -- last particle left the screen
end

--- @overload
function bt.EnemyDisappearedAnimation:finish()
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
function bt.EnemyDisappearedAnimation:draw()
    for i = 1, self._n_targets do
        --self._snapshots[i]:draw()
        for _, shape in pairs(self._particle_shapes[i]) do
            shape:draw()
        end

        --[[
        self._grounds[i]:draw()
        for _, particle in pairs(self._particles[i]) do
            particle:draw()
        end
        ]]--
    end
end