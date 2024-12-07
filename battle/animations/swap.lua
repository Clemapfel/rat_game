rt.settings.battle.animations.swap = {
    duration = 4
}

--- @class bt.Animation.SWAP
bt.Animation.SWAP = meta.new_type("SWAP", rt.Animation, function(scene, sprite_a, sprite_b)
    meta.assert_isa(sprite_a, bt.EntitySprite)
    meta.assert_isa(sprite_b, bt.EntitySprite)

    local a_x, _ = sprite_a:get_position()
    local b_x, _ = sprite_b:get_position()

    local a, b
    if a_x < b_x then
        a, b = sprite_a, sprite_b
    else
        a, b = sprite_b, sprite_a
    end

    local duration = rt.settings.battle.animations.swap.duration
    return meta.new(bt.Animation.SWAP, {
        _scene = scene,
        _target_a = a,
        _target_b = b,

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

        _draw_order = function() end,

        _elapsed = 0,
        _duration = duration,
        _time_multiplier = 1,

        _a_path = nil, -- rt.Path
        _b_path = nil, -- rt.Path
    })
end)

--- @override
function rt.Animation.SWAP:start()
    local target_a_x, target_a_y, target_a_w, target_a_h = rt.aabb_unpack(self._target_a:get_bounds())
    local target_b_x, target_b_y, target_b_w, target_b_h = rt.aabb_unpack(self._target_b:get_bounds())

    -- a is always left of b

    local n_vertices = 16
    local step = 2 * math.pi / n_vertices / 2

    local center_x = mix(target_a_x + 0.5 * target_a_w, target_b_x + 0.5 * target_b_w, 0.5)
    local center_y = mix(target_a_y + 0.5 * target_a_h, target_b_y + 0.5 * target_b_h, 0.5)
    local x_radius = 0.5 * math.abs(target_b_x - target_a_x)
    local y_radius = 1 * rt.settings.margin_unit

    local a_vertices = {}
    local b_vertices = {}
    for angle = 0, 2 * math.pi, step do
        table.insert(a_vertices, x_radius + math.cos(angle) * x_radius)
        table.insert(a_vertices, 0 + math.sin(angle) * y_radius)

        table.insert(b_vertices, -x_radius - math.cos(angle + 2 * math.pi) * x_radius)
        table.insert(b_vertices, 0 + math.sin(angle + 2 * math.pi) * y_radius)
    end

    self._a_path = rt.Path(a_vertices)
    self._b_path = rt.Path(b_vertices)
end

--- @override
function bt.Animation.SWAP:finish()
    self._target_a:set_is_visible(true)
    self._target_b:set_is_visible(true)
end

--- @override
function bt.Animation.SWAP:update(delta)
    self._elapsed = self._elapsed + delta
    --self._time_multiplier = self._time_multiplier + 4 * delta

    local value = math.fmod((self._elapsed * self._time_multiplier) / self._duration, 1)

    if value > 0.5 then
        self._draw_order = function()
            love.graphics.push()
            love.graphics.translate(self._a_x + self._a_x_offset, self._a_y + self._a_y_offset)
            self._target_a:draw()
            love.graphics.pop()

            love.graphics.push()
            love.graphics.translate(self._b_x + self._b_x_offset, self._b_y + self._b_y_offset)
            self._target_b:draw()
            love.graphics.pop()
        end
    else
        self._draw_order = function()
            love.graphics.push()
            love.graphics.translate(self._b_x + self._b_x_offset, self._b_y + self._b_y_offset)
            self._target_b:draw()
            love.graphics.pop()

            love.graphics.push()
            love.graphics.translate(self._a_x + self._a_x_offset, self._a_y + self._a_y_offset)
            self._target_a:draw()
            love.graphics.pop()
        end
    end

    self._a_x, self._a_y = self._a_path:at(math.fmod(value + 0.5, 1))
    self._b_x, self._b_y = self._b_path:at(value)

    return self._elapsed >= self._duration
end

--- @override
function bt.Animation.SWAP:draw()
    self._draw_order()
    self._a_path:draw()
    self._b_path:draw()
end