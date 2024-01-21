rt.settings.particle_emitter = {
    default_emission_rate = 10,
    default_count = 100,
    default_particle_lifetime = 1,
}

--- @class rt.ParticleEmitter
rt.ParticleEmitter = meta.new_type("ParticleEmitter", function(particle)
    meta.assert_isa(particle, rt.Drawable)
    local out = meta.new(rt.ParticleEmitter, {
        _particle = particle,
        _particle_texture = rt.RenderTexture(),
        _native = {}, -- love.ParticleSystem
        _bounds = rt.AABB(0, 0, 1, 1)
    }, rt.Drawable, rt.Animation, rt.Widget)

    out:_snapshot_particle()
    out._native = love.graphics.newParticleSystem(out._particle_texture._native)

    out._native:setEmissionRate(rt.settings.particle_emitter.default_emission_rate)
    out._native:setParticleLifetime(rt.settings.particle_emitter.default_particle_lifetime)
    out._native:setSpeed(0, 0)
    out._native:setSpread(rt.degrees_to_radians(0))
    out._native:setDirection(rt.degrees_to_radians(-90))
    out._native:setLinearAcceleration(0, -100)
    out._native:setColors(
        1, 1, 1, 0, -- 1 : 5 : 1, ratio determines how long the particle will stay at given opacity
        1, 1, 1, 1,
        1, 1, 1, 1,
        1, 1, 1, 1,
        1, 1, 1, 1,
        1, 1, 1, 1,
        1, 1, 1, 0
    )
    out._native:setSizes(1, 1)
    out._native:setInsertMode("bottom")
    return out
end)

--- @brief [internal]
function rt.ParticleEmitter:_snapshot_particle()
    local particle = self._particle
    local w, h = particle:measure()
    if w ~= self._particle_texture:get_width() or h ~= self._particle_texture:get_height() then
        self._particle_texture = rt.RenderTexture(clamp(w, 1), clamp(h, 1))
        self._particle_texture:set_scale_mode(rt.TextureScaleMode.LINEAR)

        if not meta.is_table(self._native) then
            self._native:setTexture(self._particle_texture._native)
        end
    end

    self._particle_texture:bind_as_render_target()
    love.graphics.clear(0, 0, 0, 0)
    particle:draw()
    self._particle_texture:unbind_as_render_target()
end

--- @brief determines how many particles are emitted
function rt.ParticleEmitter:set_density(emissions_per_second, max_number_of_particles)
    self._native:setEmissionRate(emissions_per_second)
    self._native:setBufferSize(max_number_of_particles)
end

--- @brief
function rt.ParticleEmitter:set_scale(lower_bound, upper_bound)
    self._native:setSizes(lower_bound, upper_bound)
end

--- @brief
function rt.ParticleEmitter:set_speed(speed)
    self._native:setLinearAcceleration(0, -1 * speed)
end

--- @brief
function rt.ParticleEmitter:set_particle_lifetime(seconds)
    self._native:setParticleLifetime(seconds)
end

--- @overload
function rt.ParticleEmitter:draw()
    love.graphics.draw(self._native)
end

--- @overload
function rt.ParticleEmitter:size_allocate(x, y, w, h)
    self._native:setPosition(x + w / 2, y + h / 2)
    self._native:setEmissionArea("uniform", w / 2, h / 2, 0, true)
    self._bounds = rt.AABB(x, y, w, h)
    self:_snapshot_particle()
end

--- @overload
function rt.ParticleEmitter:realize()
    self:set_is_animated(true)
    self._native:start()
    rt.Widget.realize(self)
end

--- @overload
function rt.ParticleEmitter:update(delta)
    self._native:update(delta)
end
