rt.settings.battle.stunned_particle_animation = {
    rounds_per_second = 0.3,
    n_particles = 2
}

--- @class bt.StunnedParticleAnimation
bt.StunnedParticleAnimation = meta.new_type("BattleStunnedParticleAnimation", rt.Widget, rt.Updatable, function()
    local type = bt.StunnedParticleAnimation
    if type._particle:get_is_realized() == false then
        type._particle:realize()
        type._particle:fit_into(0, 0)
        type._particle_w, type._particle_h = type._particle:measure()
    end

    return meta.new(bt.StunnedParticleAnimation, {
        _particles = {}, -- Table<{x, y, z}>
        _path_center_x = 0,
        _path_center_y = 0,
        _path_x_radius = 0,
        _path_y_radius = 0,
        _elapsed = 0
    })
end, {
    _particle = rt.Sprite("stunned_particle"),
    _particle_w = 0,
    _particle_h = 0
})

--- @override
function bt.StunnedParticleAnimation:realize()
    if self:already_realized() then return end
    for i = 1, rt.settings.battle.stunned_particle_animation.n_particles do
        table.insert(self._particles, {
            x = 0,
            y = 0,
            z = 0
        })
    end
end

--- @override
function bt.StunnedParticleAnimation:size_allocate(x, y, width, height)
    self._path_center_x = x + 0.5 * width
    self._path_center_y = y + 0.5 * height
    self._path_x_radius = 0.5 * width
    self._path_y_radius = 0.5 * height
    self:update(0)
end

--- @override
function bt.StunnedParticleAnimation:update(delta)
    self._elapsed = self._elapsed + delta
    local duration = 1 / rt.settings.battle.stunned_particle_animation.rounds_per_second
    duration = duration + ((meta.hash(self) % 255) / 255) -- sprites are on different cycles
    local fraction = math.fmod(self._elapsed, duration) / duration

    local offset = 1 / rt.settings.battle.stunned_particle_animation.n_particles
    for i, particle in ipairs(self._particles) do
        local current_fraction = fract(fraction + i * offset)
        local angle = current_fraction * math.pi * 2
        particle.x = self._path_center_x + math.cos(angle) * self._path_x_radius - 0.5 * self._particle_w
        particle.y = self._path_center_y + math.sin(angle) * self._path_y_radius - 0.5 * self._particle_h

        -- compute scale
        local ratio = math.min(self._path_x_radius, self._path_y_radius) / math.max(self._path_x_radius, self._path_y_radius)
        local min_scale, max_scale = 1 - ratio, 1 + ratio
        particle.z = rt.cosine_wave(current_fraction + 0.5, 1) * (max_scale - min_scale) + min_scale
    end
end

--- @override
function bt.StunnedParticleAnimation:draw()
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.ellipse("line", self._path_center_x, self._path_center_y, self._path_x_radius, self._path_y_radius)

    for particle in values(self._particles) do
        love.graphics.push()
        love.graphics.origin()
        love.graphics.translate(particle.x, particle.y)
        love.graphics.translate(0.5 * self._particle_w, 0.5 * self._particle_h)
        love.graphics.scale(particle.z)
        love.graphics.translate(-0.5 * self._particle_w, -0.5 * self._particle_h)
        self._particle:draw()
        love.graphics.pop()
    end
end