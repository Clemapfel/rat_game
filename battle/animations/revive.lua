rt.settings.battle.animations.revive = {
    duration = 6,
    n_particles = 16
}

--- @class bt.Animation.REVIVE
bt.Animation.REVIVE = meta.new_type("REVIVE", rt.Animation, function(scene, entity)
    meta.assert_isa(scene, bt.Scene)
    meta.assert_isa(entity, bt.Entity)

    local settings = rt.settings.battle.animations.revive
    return meta.new(bt.Animation.REVIVE, {
        _scene = scene,
        _entity = entity,
        _sprite = nil,

        _sprite_x = 0,
        _sprite_y = 0,
        _sprite_path = nil, -- rt.Path

        _circle = nil, -- rt.VertexShape
        _trapezoid = nil, -- "
        _trapezoid_left_aa = nil, -- "
        _trapezoid_right_aa = nil, -- "
        _shadow = nil, -- "
        _shadow_fade_in_animation = rt.TimedAnimation(0.1, 0, 1),
        _shadow_fade_out_animation = rt.TimedAnimation(0.1, 1, 0),

        _before_light_hold = rt.TimedAnimation(0.5),
        _after_light_before_descend_hold = rt.TimedAnimation(0.5),
        _after_descend_hold = rt.TimedAnimation(0.25),

        _sprite_path = nil, -- rt.Path
        _sprite_animation = rt.TimedAnimation(settings.duration, 1, 0, rt.InterpolationFunctions.EXPONENTIAL_DECELERATION),
        _sprite_x = 0,
        _sprite_y = 0,
        _sprite_scale = 0,
        _sprite_scale_offset_x = 0,
        _sprite_scale_offset_y = 0,

        _n_particles = settings.n_particles,
        _particle_shape = nil, -- rt.VertexShape
        _particles = {},
        _particle_path = nil, -- rt.Path
        _particle_path_animation = rt.TimedAnimation(settings.duration),
        _particle_opacity = 1,
        _particle_floor = 0,
        _particle_opacity_animation = rt.TimedAnimation(settings.duration, 0, 1, rt.InterpolationFunctions.HANN_LOWPASS, 6)
    })
end)

do
    local _particle_mesh = nil

    --- @override
    function rt.Animation.REVIVE:start()
        local x, y, w, h = rt.aabb_unpack(self._scene:get_bounds())
        local sprite_x, sprite_y = self._sprite:get_position()
        local sprite_w, sprite_h = self._sprite:get_size()
        local m = rt.settings.margin_unit

        self._sprite_scale_offset_x = -sprite_x - 0.5 * sprite_w
        self._sprite_scale_offset_y = -sprite_y - 0.5 * sprite_h

        local center_x, center_y = x + 0.5 * w, sprite_y + sprite_h
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
        self._particle_floor = center_y

        for i = 1, self._n_particles do
            local particle_x = rt.random.number(center_x - lower_r, center_x + lower_r)
            local particle_y = rt.random.number(0, -sprite_y)

            table.insert(self._particles, {
                x = particle_x,
                y = particle_y,
                mass = rt.random.number(0.75, 3),
                scale = rt.random.number(0.7, 1)
            })
        end

        self._particle_path = rt.Path(
            0, 0,
            0, lower_y
        )

        self._sprite_path = rt.Path(
            0, -sprite_y - sprite_h,
            0, 0
        )
    end
end

--- @override
function bt.Animation.REVIVE:finish()
    self._sprite:set_opacity(1)
end

--- @override
function bt.Animation.REVIVE:update(delta)
    self._shadow_fade_in_animation:update(delta)
    self._shadow:set_opacity(self._shadow_fade_in_animation:get_value())

    if self._shadow_fade_in_animation:get_is_done() then
        self._before_light_hold:update(delta)
        if not self._before_light_hold:get_is_done() then
            return rt.AnimationResult.CONTINUE
        end

        if self._before_light_hold:get_is_done() then
            self._after_light_before_descend_hold:update(delta)
            if not self._after_light_before_descend_hold:get_is_done() then
                return rt.AnimationResult.CONTINUE
            end
        end
    end

    local is_done = true
    for animation in range(
        self._sprite_animation,
        self._particle_opacity_animation,
        self._sprite_animation,
        self._particle_path_animation
    ) do
        animation:update(delta)
        is_done = is_done and animation:get_is_done()
    end
    if is_done then
        self._shadow_fade_out_animation:update(delta)
        self._shadow:set_opacity(self._shadow_fade_out_animation:get_value())
        self._after_descend_hold:update(delta)
    end

    local gravity = rt.settings.battle.animations.revive.particle_gravity
    for particle in values(self._particles) do
        local _, particle_y = self._particle_path:at(self._particle_path_animation:get_value() * particle.mass)
        particle.y = particle_y
        if particle.y > self._particle_floor then particle.y = self._particle_floor end
    end

    local sprite_value = self._sprite_animation:get_value()
    self._sprite_x, self._sprite_y = self._sprite_path:at(sprite_value)
    self._sprite:set_opacity(sprite_value)
    self._sprite_scale = self._sprite_animation:get_value()
    self._particle_opacity = self._particle_opacity_animation:get_value()
    return self._shadow_fade_out_animation:get_is_done() and self._scene:get_are_sprites_done_repositioning()
end

--- @override
function bt.Animation.REVIVE:draw()
    self._shadow:draw()
    if  self._shadow_fade_in_animation:get_is_done() and
        self._before_light_hold:get_is_done()
    then
        self._circle:draw()
        if self._after_light_before_descend_hold:get_is_done() then
            love.graphics.push()
            love.graphics.translate(self._sprite_x, self._sprite_y)
            love.graphics.translate(-self._sprite_scale_offset_x, -self._sprite_scale_offset_y)
            love.graphics.scale(self._sprite_scale)
            love.graphics.translate(self._sprite_scale_offset_x, self._sprite_scale_offset_y)
            self._sprite:draw_snapshot()
            love.graphics.pop()
        end

        self._trapezoid_left_aa:draw()
        self._trapezoid:draw()
        self._trapezoid_right_aa:draw()

        if self._after_light_before_descend_hold:get_is_done() then
            for particle in values(self._particles) do
                love.graphics.push()
                love.graphics.origin()
                love.graphics.setColor(1, 1, 1, self._particle_opacity)
                love.graphics.translate(particle.x, particle.y)
                love.graphics.scale(particle.scale, particle.scale)
                love.graphics.draw(self._particle_shape._native)
                love.graphics.pop()
            end
        end
    end
end