rt.settings.battle.animations.swap = {
    duration = 5
}

--- @class bt.Animation.SWAP
bt.Animation.SWAP = meta.new_type("SWAP", rt.Animation, function(scene, sprite_a, sprite_b)
    meta.assert_isa(sprite_a, bt.EntitySprite)
    meta.assert_isa(sprite_b, bt.EntitySprite)

    local duration = rt.settings.battle.animations.swap.duration
    return meta.new(bt.Animation.SWAP, {
        _scene = scene,
        _target_a = sprite_a,
        _target_b = sprite_b,

        _a_x = 0,
        _a_y = 0,
        _a_x_offset = 0,
        _a_y_offset = 0,
        _a_scale = 1,

        _b_x = 0,
        _b_y = 0,
        _b_x_offset = 0,
        _b_y_offset = 0,
        _b_scale = 1,

        _animation = rt.TimedAnimation(duration, 0, 1, rt.InterpolationFunctions.LINEAR_BANDPASS),

        _path = nil, -- rt.Path

    })
end)

--- @override
function rt.Animation.SWAP:start()
    local target_a_x, target_a_y = self._target_a:get_position()
    local target_a_w, target_a_h = self._target_a:get_size()
    local target_b_x, target_b_y = self._target_b:get_position()
    local target_b_w, target_b_h = self._target_a:get_size()

    self._a_x_offset, self._a_y_offset = target_a_x + 0.5 * target_a_w, target_a_y + 0.5 * target_a_h
    self._b_x_offset, self._b_y_offset = target_b_x + 0.5 * target_b_w, target_b_y + 0.5 * target_b_h

    local center_x = mix(target_a_x + 0.5 * target_a_w, target_b_x + 0.5 * target_b_w, 0.5)
    local center_y = mix(target_a_y + 0.5 * target_a_h, target_b_y + 0.5 * target_b_h, 0.5)
    local x_radius = math.abs(target_a_x - target_b_x) / 2
    local y_radius = 0.1 * self._scene:get_bounds().height


    local vertices = {}
    local n_vertices_per_path = 64
    local step = 2 * math.pi / (2 * n_vertices_per_path)
    for angle = 0, 2 * math.pi, step do
        table.insert(vertices, center_x + math.cos(angle) * x_radius)
        table.insert(vertices, center_y + math.sin(angle) * y_radius)
    end

    self._path = rt.Path(vertices)

    self._target_a:set_is_visible(false)
    self._target_b:set_is_visible(false)
end

--- @override
function bt.Animation.SWAP:finish()
    self._target_a:set_is_visible(true)
    self._target_b:set_is_visible(true)
end

--- @override
function bt.Animation.SWAP:update(delta)
    local is_done = true
    for animation in range(self._animation) do
        animation:update(delta)
        is_done = is_done and animation:get_is_done()
    end

    local n_cycles = 1
    self._a_x, self._a_y = self._path:at(math.fmod(self._animation:get_value() * n_cycles, 1))
    self._b_x, self._b_y = self._path:at(math.fmod(self._animation:get_value() * n_cycles + 0.5, 1))

    return is_done
end

--- @override
function bt.Animation.SWAP:draw()
    self._path:draw()

    love.graphics.push()
    love.graphics.translate(self._a_x - self._a_x_offset, self._a_y - self._a_y_offset)
    --love.graphics.circle("fill", 0, 0, 50)
    self._target_a:draw_snapshot()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(self._b_x - self._b_x_offset, self._b_y - self._b_y_offset)
    --love.graphics.circle("fill", 0, 0, 50)
    self._target_b:draw_snapshot()
    love.graphics.pop()
end