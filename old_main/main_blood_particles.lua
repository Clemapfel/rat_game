require "include"

local ffi = require("ffi")

local ffi = require("ffi")

local Particle = {}
Particle.__index = Particle

function Particle.new(x, y, radius, vx, vy)
    local self = setmetatable({}, Particle)
    self.x = x
    self.y = y
    self.radius = radius
    self.vx = vx or 0
    self.vy = vy or 0
    self.density = 0
    self.pressure = 0
    self.fx = 0
    self.fy = 0
    return self
end

local SPH = {}
SPH.__index = SPH

function SPH.new(width, height)
    local self = setmetatable({}, SPH)
    self.width = width
    self.height = height
    self.particles = {}
    self.h = 16
    self.mass = 2.5
    self.rest_density = 300
    self.gas_constant = 2000
    self.viscosity = 250
    self.dt = 0.0008
    self.gravity = 12000
    self.restitution = 0.3
    self.default_radius = 4
    return self
end

function SPH:add_particle(x, y, radius, vx, vy)
    radius = radius or self.default_radius
    local to_add = Particle.new(x, y, radius, vx, vy)
    table.insert(self.particles, to_add)
    return to_add
end

function SPH:compute_density()
    local h2 = self.h * self.h

    for i = 1, #self.particles do
        local p1 = self.particles[i]
        p1.density = 0

        for j = 1, #self.particles do
            local p2 = self.particles[j]
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local r2 = dx * dx + dy * dy
            local combined_radius = p1.radius + p2.radius

            if r2 < h2 then
                p1.density = p1.density + self.mass * (315 / (64 * math.pi * self.h^9)) * (h2 - r2)^3
            end
        end

        p1.pressure = self.gas_constant * (p1.density - self.rest_density)
    end
end

function SPH:compute_forces()
    local h2 = self.h * self.h

    for i = 1, #self.particles do
        local p1 = self.particles[i]
        p1.fx = 0
        p1.fy = self.gravity

        for j = 1, #self.particles do
            if i ~= j then
                local p2 = self.particles[j]
                local dx = p1.x - p2.x
                local dy = p1.y - p2.y
                local r2 = dx * dx + dy * dy
                local combined_radius = p1.radius + p2.radius

                if r2 < h2 then
                    local r = math.sqrt(r2)
                    local pressure_force = -self.mass * (p1.pressure + p2.pressure) / (2 * p2.density) *
                        (45 / (math.pi * self.h^6)) * (self.h - r)^2
                    p1.fx = p1.fx + pressure_force * dx / r
                    p1.fy = p1.fy + pressure_force * dy / r

                    local dvx = p2.vx - p1.vx
                    local dvy = p2.vy - p1.vy
                    local viscosity_force = self.viscosity * self.mass / p2.density *
                        (45 / (math.pi * self.h^6)) * (self.h - r)
                    p1.fx = p1.fx + viscosity_force * dvx
                    p1.fy = p1.fy + viscosity_force * dvy
                end

                if r2 < combined_radius * combined_radius then
                    local r = math.sqrt(r2)
                    local overlap = combined_radius - r
                    local nx = dx / r
                    local ny = dy / r
                    local relative_velocity_x = p1.vx - p2.vx
                    local relative_velocity_y = p1.vy - p2.vy
                    local impulse = (-(1 + self.restitution) * (relative_velocity_x * nx + relative_velocity_y * ny)) / 2

                    p1.fx = p1.fx + impulse * nx * self.mass * 100
                    p1.fy = p1.fy + impulse * ny * self.mass * 100
                end
            end
        end
    end
end

function SPH:integrate()
    for _, p in ipairs(self.particles) do
        local ax = p.fx / p.density
        local ay = p.fy / p.density

        p.vx = p.vx + ax * self.dt
        p.vy = p.vy + ay * self.dt

        p.x = p.x + p.vx * self.dt
        p.y = p.y + p.vy * self.dt

        if p.x < p.radius then
            p.x = p.radius
            p.vx = -p.vx * self.restitution
        elseif p.x > self.width - p.radius then
            p.x = self.width - p.radius
            p.vx = -p.vx * self.restitution
        end

        if p.y < p.radius then
            p.y = p.radius
            p.vy = -p.vy * self.restitution
        elseif p.y > self.height - p.radius then
            p.y = self.height - p.radius
            p.vy = -p.vy * self.restitution
        end
    end
end

function SPH:update()
    self:compute_density()
    self:compute_forces()
    self:integrate()
end

---

local screen_w, screen_h = 800, 600
local sim = SPH.new(screen_w, screen_h)
local particle_radius = 10
local n_particles = 100

love.load = function()
    local r = particle_radius
    local hue = 0
    local hue_step = 1 / n_particles
    for i = 1, n_particles do
        local particle = sim:add_particle(
            rt.random.number(0 + 2 * r, screen_w - 2 * r),
            rt.random.number(0 + 2 * r, screen_h - 2 * r),
            particle_radius,
            0, 0
        )

        local rgba = rt.lcha_to_rgba(rt.LCHA(0.8, 1, hue))
        hue = hue + hue_step
        particle.color_r = rgba.r
        particle.color_g = rgba.g
        particle.color_b = rgba.b
        particle.color_a = rgba.a
    end
end

love.update = function()
    sim:update()
end

love.draw = function()
    for particle in values(sim.particles) do
        love.graphics.setColor(particle.color_r, particle.color_g, particle.color_b, particle.color_a)
        love.graphics.circle("fill", particle.x, particle.y, particle.radius)
    end
end