rt.settings.battle.animations.enemy_revived = {
    duration = 6,
    particle_gravity = 40
}

--- @class bt.Animation.ENEMY_REVIVED
bt.Animation.ENEMY_REVIVED = meta.new_type("ENEMY_REVIVED", rt.Animation, function(scene, sprite)
    local settings = rt.settings.battle.animations.enemy_revived
    return meta.new(bt.Animation.ENEMY_REVIVED, {
        _scene = scene,
        _sprite = sprite,

        _snapshot = nil, -- rt.RenderTexture
        _sprite_x = 0,
        _sprite_y = 0,

        _circle = nil, -- rt.VertexShape
        _trapezoid = nil, -- "
        _trapezoid_left_aa = nil, -- "
        _trapezoid_right_aa = nil, -- "
        _shadow = nil, -- "

        _sprite_path = nil, -- rt.Path
        _sprite_path_animation = rt.TimedAnimation(settings.duration),

        _n_particles = 16,
        _particle_shape = nil, -- rt.VertexShape
        _particles = {}
    })
end)

do
    local _particle_mesh = nil

    --- @override
    function rt.Animation.ENEMY_REVIVED:start()
        local x, y, w, h = rt.aabb_unpack(self._scene:get_bounds())
        local sprite_x, sprite_y = self._sprite:get_position()
        local sprite_w, sprite_h = self._sprite:get_size()
        local m = rt.settings.margin_unit

        local center_x, center_y = x + 0.5 * w, y + 0.5 * h
        local circle_w = sprite_w + 2 * m
        local circle_h = 0.2 * circle_w

        local black = rt.Palette.BLACK
        local white = rt.Palette.WHITE
        local light_alpha = 0.7

        do
            local vertices = {
                {center_x, center_y, 0, 0, white.r, white.g, white.b, 1}
            }
            local n_outer_vertices = 64
            local step = 2 * math.pi / n_outer_vertices
            local vertex_i = 1
            local side_eps = (12 / 64) * 2 * math.pi
            for angle = 0, 2 * math.pi, step do
                local cx, cy = center_x + math.cos(angle) * circle_w / 2, center_y + math.sin(angle) * circle_h / 2
                table.insert(vertices, {cx, cy, 0, 0, black.r, black.g, black.b, 1})
                vertex_i = vertex_i + 1
            end
            local vertex_map = {n_outer_vertices, 1, 2}
            for outer_i = 2, n_outer_vertices - 1 do
                for i in range(1, outer_i, outer_i + 1) do
                    table.insert(vertex_map, i)
                end
            end
            self._circle = rt.VertexShape(vertices, rt.MeshDrawMode.TRIANGLES)
            self._circle._native:setVertexMap(vertex_map)
        end

        self._shadow = rt.VertexRectangle(x, y, w, h)
        self._shadow:set_color(black)

        local lower_r = circle_w / 2
        local upper_r = 0.1 * circle_w / 2
        local upper_y, lower_y = y - 0.05 * circle_w, center_y
        local aa_width = 15

        do
            local function bright(x, y)
                return {x, y, 0, 0, white.r, white.g, white.b, 1}
            end

            local function dark(x, y)
                return {x, y, 0, 0, black.r, black.g, black.b, 0}
            end

            self._trapezoid_left_aa = rt.VertexShape({
                dark(center_x - upper_r - aa_width, upper_y),
                bright(center_x - upper_r, upper_y),
                dark(center_x - lower_r, lower_y),
                dark(center_x - lower_r - aa_width, lower_y)
            })

            self._trapezoid_right_aa = rt.VertexShape({
                bright(center_x + upper_r, upper_y),
                dark(center_x + upper_r + aa_width, upper_y),
                dark(center_x + lower_r + aa_width, lower_y),
                dark(center_x + lower_r, lower_y)
            })

            self._trapezoid = rt.VertexShape({
                bright(center_x - upper_r, upper_y),
                bright(center_x, upper_y),
                bright(center_x + upper_r, upper_y),
                dark(center_x + lower_r, lower_y),
                dark(center_x, lower_y),
                dark(center_x - lower_r, lower_y),
            })

        end


        if _particle_mesh == nil then
            local particle_r = m
            _particle_mesh = rt.VertexCircle(0, 0, particle_r, particle_r, 16)

            _particle_mesh:set_vertex_color(1, white)
            for i = 2, _particle_mesh:get_n_vertices() do
                _particle_mesh:set_vertex_color(i, white.r, white.g, white.b, 0)
            end
        end
        self._particle_shape = _particle_mesh

        for i = 1, self._n_particles do
            local particle_x = love.math.random(center_x - lower_r, center_x + lower_r)
            local particle_y = love.math.random(y, sprite_y)

            table.insert(self._particles, {
                x = particle_x,
                y = particle_y,
                mass = love.math.random(0.8, 1)
            })
        end

    end
end

--- @override
function bt.Animation.ENEMY_REVIVED:update(delta)
    local is_done = true
    for animation in range(
        self._sprite_path_animation
    ) do
        animation:update(delta)
        is_done = is_done and animation:get_is_done()
    end

    local gravity = rt.settings.battle.animations.enemy_revived.particle_gravity
    for particle in values(self._particles) do
        particle.y = particle.y + gravity * delta * particle.mass
    end

    return is_done
end

--- @override
function bt.Animation.ENEMY_REVIVED:draw()
    self._shadow:draw()
    self._circle:draw()
    self._trapezoid_left_aa:draw()
    self._trapezoid:draw()
    self._trapezoid_right_aa:draw()

    for particle in values(self._particles) do
        self._particle_shape:draw(particle.x, particle.y)
    end
end